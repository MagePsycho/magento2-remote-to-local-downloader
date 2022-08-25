#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "./.m2-remote-to-local.conf" ]]; then
    echo "Config file does not exist: ./.m2-remote-to-local.conf"
    exit 1
fi

# Do not Edit
SSH_HOST=''
SSH_USER=''
SSH_PORT='22'
USE_PASS=0
SSH_PASS=''
SSH_PRIVATE_KEY=''
SSH_PASSPHRASE=''
M2_ROOT_DIR=''
M2_BACKUP_DIR=''
M2_PROJECT_NAME=''
source "./.m2-remote-to-local.conf"

echo 'Checking prerequisites...'
if [[ -z "${M2_ROOT_DIR}" ]]; then
    echo "M2_ROOT_DIR is empty"
    exit 1
fi
if [[ -z "${M2_BACKUP_DIR}" ]]; then
    echo "M2_BACKUP_DIR is empty"
    exit 1
fi
if [[ -z "${M2_PROJECT_NAME}" ]]; then
    echo "M2_PROJECT_NAME is empty"
    exit 1
fi

echo 'Connecting to remote...'
_sshPassOption=
_sshOption=
_scpOption=
if [[ "$USE_PASS" -eq 1 ]]; then
    _sshPassOption="sshpass -p ${SSH_PASS} "
    _sshOption="-o StrictHostKeyChecking=no"
    _scpOption="-P ${SSH_PORT}"
else
		if [[ -z "$SSH_PASSPHRASE" ]]; then
        _sshPassOption=""
    else
        _sshPassOption="sshpass -Ppassphrase -p ${SSH_PASSPHRASE} "
		fi
    _sshOption="-i ${SSH_PRIVATE_KEY}"
    _scpOption="-i ${SSH_PRIVATE_KEY} -P ${SSH_PORT}"
fi

#sshpass -p "${SSH_PASS}" ssh -o StrictHostKeyChecking=no -T "$SSH_USER"@"$SSH_HOST" -p "$SSH_PORT" << EOL
#sshpass -Ppassphrase -p "${SSH_PASSPHRASE}" ssh -i "${SSH_PRIVATE_KEY}" -T "$SSH_USER"@"$SSH_HOST" -p "$SSH_PORT" << EOL
#ssh -i "${SSH_PRIVATE_KEY}" -T "$SSH_USER"@"$SSH_HOST" -p "$SSH_PORT" << EOL

${_sshPassOption}ssh $_sshOption -T "$SSH_USER"@"$SSH_HOST" -p "$SSH_PORT" << EOL
cd "$M2_ROOT_DIR"
echo 'Installing backup script...'
curl -0 https://raw.githubusercontent.com/MagePsycho/magento2-db-code-backup-bash-script/master/src/mage2-db-code-backup.sh -o m2-backup.sh
chmod +x ./m2-backup.sh

echo 'Collecting stack versions...'
php -v
bin/magento --version
composer --version
mysql --version

echo 'Backing up code & db...'
./m2-backup.sh --backup-db --backup-code --skip-media --backup-name="$M2_PROJECT_NAME" --src-dir="$M2_ROOT_DIR" --dest-dir="$M2_BACKUP_DIR"
# @todo in-case if mysqldump throws an error
# bin/magento config:set system/backup/functionality_enabled 1
# bin/magento setup:backup --db
# DB backup path: /var/www/html/var/backups/{timestamp}_db.sql
rm -f ./m2-backup.sh
EOL

echo 'Downloading remote code & db backups...'
${_sshPassOption}scp $_scpOption "$SSH_USER"@"$SSH_HOST":"$M2_BACKUP_DIR"/"$M2_PROJECT_NAME".sql.gz ./
${_sshPassOption}scp $_scpOption "$SSH_USER"@"$SSH_HOST":"$M2_BACKUP_DIR"/"$M2_PROJECT_NAME".tar.gz ./

echo 'Preparing env.php file...'
${_sshPassOption}scp $_scpOption "$SSH_USER"@"$SSH_HOST":"$M2_ROOT_DIR"/app/etc/env.php ./
$(php -r '
  $env = include "./env.php";

  $env["backend"]["frontName"] = "backend";
  $env["db"]["connection"]["default"]["host"] = "db";
  $env["db"]["connection"]["default"]["username"] = "magento";
  $env["db"]["connection"]["default"]["password"] = "magento";
  $env["db"]["connection"]["default"]["dbname"] = "magento";

  //$env["downloadable_domains"] = ["{M2_PROJECT_NAME}.test"];
  $sessionSave = $env["session"]["save"] ?? "";
  if ($sessionSave == "redis") {
      $env["session"]["redis"] = [
          "host" => "redis",
          "port" => "6379",
          "password" => "",
          "timeout" => "2.5",
          "persistent_identifier" => "",
          "database" => "2",
          "compression_threshold" => "2048",
          "compression_library" => "gzip",
          "log_level" => "1",
          "max_concurrency" => "20",
          "break_after_frontend" => "5",
          "break_after_adminhtml" => "30",
          "first_lifetime" => "600",
          "bot_first_lifetime" => "60",
          "bot_lifetime" => "7200",
          "disable_locking" => "0",
          "min_lifetime" => "60",
          "max_lifetime" => "2592000",
          "sentinel_master" => "",
          "sentinel_servers" => "",
          "sentinel_connect_retries" => "5",
          "sentinel_verify_master" => "0"
      ];
  }

  $defaultCaching = $env["cache"]["frontend"]["default"]["backend"] ?? null;
  if ($defaultCaching && strpos($defaultCaching, "Redis") !== false) {
      $env["cache"]["frontend"]["default"]["backend_options"] = [
          "server" => "redis",
          "database" => "0",
          "port" => "6379",
          "password" => "",
          "compress_data" => "1",
          "compression_lib" => ""
      ];
  }
  $pageCaching = $env["cache"]["frontend"]["page_cache"]["backend"] ?? null;
  if ($pageCaching && strpos($pageCaching, "Redis") !== false) {
      $env["cache"]["frontend"]["page_cache"]["backend_options"] = [
          "server" => "redis",
          "database" => "1",
          "port" => "6379",
          "password" => "",
          "compress_data" => "0",
          "compression_lib" => ""
      ];
  }

  $envContent =  "<?php" . PHP_EOL . " return " . var_export($env, true) . ";";
  file_put_contents("./env-warden.php", $envContent);
')

echo "Code, DB dump & env.php has been successfully downloaded:"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "> ${M2_PROJECT_NAME}.sql.gz"
echo "> ${M2_PROJECT_NAME}.tar.gz"
echo "> env.php -> env-warden.php"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Now you can setup the project locally with warden"
