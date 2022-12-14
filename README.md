# Magento 2 Remote to Local Downloader

This is a bash script to connect to remote server, take back up of Magento 2 code base + database and download them for local setup.

*It utilizes this bash script under the hood: https://github.com/MagePsycho/magento2-db-code-backup-bash-script*

## INSTALL
You can simply download the script file and give the executable permission.
```
curl -0 https://raw.githubusercontent.com/MagePsycho/magento2-remote-to-local-downloader/master/src/m2-remote-to-local.sh -o m2-remote-to-local.sh
chmod +x m2-remote-to-local.sh
```

To make it system-wide command (recommended)
```
mv m2-remote-to-local.sh ~/bin/m2-remote-to-local
#OR
#mv m2-remote-to-local.sh /usr/local/bin/m2-remote-to-local
```

You also need a config file `.m2-remote-to-local.conf` to configure the SSH and remote directory settings.  
The config template can be downloaded as
```
curl -0 https://raw.githubusercontent.com/MagePsycho/magento2-remote-to-local-downloader/master/.m2-remote-to-local.conf.dist -o .m2-remote-to-local.conf
```
*Note: `.m2-remote-to-local.conf` file should reside in your local project directory.*

## PREREQUISITES

### Install dependent commands
*It uses `sshpass`, `ssh` & `scp` commands to connect, backup and download the project files from remote.*

If you haven't installed the `sshpass`, you can install as
```
# On Ubuntu
sudo apt-get install sshpass

# On Mac
# brew install hudochenkov/sshpass/sshpass
```

### Configure SSH Settings
Before executing the command, you need to configure the settings in `.m2-remote-to-local.conf` file.  
And the settings looks like this:
```
# =================================
# SSH Basic Information
# =================================
SSH_HOST=''
SSH_USER=''
SSH_PORT='22'

# =================================
# Types of Authentication
# =================================

# 1. Password based
# Use 1 to enable, 0 to disable
AUTH_PASS=0
SSH_PASS=''

# 2. Private Key (.pem) based
# Use 1 to enable, 0 to disable
AUTH_PEM=0
# Absolute path to private key
SSH_PRIVATE_KEY=''

# 3. Public Key (~/.ssh/id_rsa.pub) based
# Use 1 to enable, 0 to disable
AUTH_PUB=0

# If passphrase has been setup for the keys
SSH_PASSPHRASE=''

# =================================
# Remote Directories
# =================================
# Name will be used as a basename for backups, ex: {project-name}.tar.gz
M2_PROJECT_NAME=''
# Use 0 if you want to include the media files
SKIP_MEDIA_FILES=1

# Absolute path to Magento 2 root directory
M2_ROOT_DIR=''
# Absolute path to backup directory
M2_BACKUP_DIR=''
```

## USAGE
After you have install required commands & configured the SSH settings, it's time for real action
```
cd /path/to/your/project

# Assuming you have already configured required settings in .m2-remote-to-local.conf (which should reside on this current directory)

m2-remote-to-local
```

On successfully operation, you will receive these files in your local
1. `{project}.tar.gz` (Codebase dump without `media`, `var`, `generation` folders and `app/etc/env.php` file)
2. `{project}.sql.gz` (Database dump)
3. `env.php` (Original file from remote - *can be safely deleted*)
4. `env-warden.php`  (Ready to use file with your Warden environment)

**Notes**  
- You can safely delete the `.m2-remote-to-local.conf` after operation or exclude it from your project's `.gitignore`
- You can safely delete the `./env.php` file if not needed further

## TODOS

 - [x] Add option to include media folders for backup
 - [ ] Refactor the bash script to utilize the standard coding
 - [ ] Make use of `bin/magento setup:backup --db` as a fallback of `mysqldump`
 - [x] Add option of housekeeping in remote
 - [ ] Add option to strip off the database for development

