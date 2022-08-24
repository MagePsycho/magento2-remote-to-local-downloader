# Magento 2 Remote to Local Downloader

This is a bash script to connect to remote server, take back up of Magento 2 code base + database and download them for local setup.

*It utilizes the bash script: https://github.com/MagePsycho/magento2-db-code-backup-bash-script*

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

## USAGE

### Configure SSH Settings
*It uses `sshpass`, `ssh` & `scp` commands to connect, backup and download the project files from remote.*

If you haven't installed the `sshpass`, you can install as
```
# On Ubuntu
sudo apt-get install sshpass

# On Mac
# brew install hudochenkov/sshpass/sshpass
```

In order to connect to remote via SSH, you need to configure the settings in `.m2-remote-to-local.conf` file.
```
curl -0 https://raw.githubusercontent.com/MagePsycho/magento2-remote-to-local-downloader/master/.m2-remote-to-local.conf.dist -o .m2-remote-to-local.conf
```

And edit the settings in `.m2-remote-to-local.conf` file as
```
SSH_HOST=''
SSH_USER=''
SSH_PORT='22'

# Use key or password?
# USE_PASS=1|0, 1 -> use password, 0 -> use key file
USE_PASS=0
SSH_PASS=''
SSH_PRIVATE_KEY=''
SSH_PASSPHRASE=''

M2_PROJECT_NAME=''
# Absolute path (without trailing slash)
M2_ROOT_DIR=''
M2_BACKUP_DIR=''
```

### Execute Commands
After you have configured the SSH settings, it's time for action
```
cd /path/to/new/project
m2-remote-to-local
```
On successfully operation, you will receive three files in your local
1. `{project}.tar.gz`
2. `{project}.sql.gz`
3. `env.php` (ready to be used with warden settings)
