#!/bin/bash
######################################################################################################
### Author: Sidney Omondi
### Version: v1.0.0
### Date: 2021-5-24 [YYY-MM-DD]
### Description:
###           Script aims to automate installation of Zabbix on CentOS
###
### Usage: ./Zabbix_install.sh
######################################################################################################

#step 1
#Set SELinux to work in permissive mode
sudo setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
#Step2
# Install Zabbix Server, frontend and agent
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
sudo dnf clean all
sudo dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent

#Step3
#Install and configure DB
# a) install MariaDB
sudo dnf -y install mariadb-server && sudo systemctl start mariadb && sudo systemctl enable mariadb

# b) change root password
mysql_secure_installation #run as final stage
# c) Create database
read -p "Enter a password for your zabbix user [zabbix] : " zabbixDBpass

sudo mysql  --execute="
CREATE DATABASE zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by '${zabbixDBpass}';
USE zabbix
SET global innodb_strict_mode='OFF';
"
# d) Import initial schema and data
yum install pv &&

mysql_import_function /usr/share/doc/zabbix-server-mysql*/create.sql.gz zabbix $zabbixDBpass zabbix

#enable strict mode
sudo mysql --execute="USE zabbix;
SET global innodb_strict_mode='ON';
"
zabbix_config_file="/etc/zabbix/zabbix_server.conf"
zabbix_php_file="/etc/php-fpm.d/zabbix.conf"
sed -i "/^DBPassword=/ s/DBPassword=/DBPassword=$zabbixDBpass/ " "${zabbix_config_file}"
sleep 0.1

#Step4
#Start Zabbix server and Agent Process
sudo systemctl restart zabbix-server zabbix-agent
sudo systemctl enable zabbix-server zabbix-agent

#Step5
#Configure firewall
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
sudo firewall-cmd --reload
#Step 6
# a) configure Zabbix frontend
sed -i "/^ /; php_value date.timezone Europe\/Riga/ s/; php_value date.timezone Europe\/Riga/php_value date.timezone Africa\/Nairobi/" "${zabbix_php_file}"

# b) Restart Apache Services
sudo systemctl restart httpd php-fpm
sudo systemctl enable httpd php-fpm
# c) Configure web frontend
echo -e "visit http://192.168.1.1/zabbix to complete installation
Enter your DB Password and continue with NEXT

and finally use default credentials , Admin and Zabbix to login
"

# d ) Optimization
# 1) zabbix
sudo tee -a /etc/zabbix/zabbix_server.conf> /dev/nu// <<EOT
StartPollers=100
StartPollersUnreachable=50
StartPingers=50
StartTrappers=10
StartDiscoverers=15
StartPreprocessors=15
StartHTTPPollers=5
StartAlerters=5
StartTimers=2
StartEscalators=2
CacheSize=128M
HistoryCacheSize=64M
HistoryIndexCacheSize=32M
TrendCacheSize=32M
ValueCacheSize=256M
EOT

# 2) MariaDB
sudo tee -a /etc/my.cnf.d/10_my_tweaks.cnf > /dev/null <<EAT
[mysqld]
max_connections = 404
innodb_buffer_pool_size = 800M

innodb-log-file-size = 128M
innodb-log-buffer-size = 128M
innodb-file-per-table = 1
innodb_buffer_pool_instances = 8
innodb_old_blocks_time = 1000
innodb_stats_on_metadata = off
innodb-flush-method = O_DIRECT
innodb-log-files-in-group = 2
innodb-flush-log-at-trx-commit = 2

tmp-table-size = 96M
max-heap-table-size = 96M
open_files_limit = 65535
max_connect_errors = 1000000
connect_timeout = 60
wait_timeout = 28800
EAT

#set Permissions
chown mysql:mysql /etc/my.cnf.d/10_my_tweaks.cnf
chmod 644 /etc/my.cnf.d/10_my_tweaks.cnf

#max_connections > total number of zabbix proxy procees +150
#automatically check and add 150 to the number
egrep "^Start.+=[0-9]" /etc/zabbix/zabbix_server.conf | awk -F "=" '{s+=$2} END {print s+150}'

#Restart Services
sudo systemctl stop zabbix-server
sudo systemctl stop mysql
sudo systemctl start mysql
sudo systemctl start zabbix-server

#step 7
#Enable and configure SELinux
sudo setsebool -P httpd_can_connect_zabbix 1
#allow connection to all TCP ports
sudo setsebool -P zabbix_can_network 1
#set SELINUX to work in enforcing mode
sudo setenforce 1 && sed -i 's/^SELINUX=.*/SELINUX=enforcing/g' /etc/selinux/config
#check status
sestatus && sleep 0.2
#create additional SELINUX policy for zabbix
sudo dnf -y install policycoreutils-python-utils
#custom policy package
grep "denied.*zabbix" /var/log/audit/audit.log | audit2allow -M zabbix_policy
#install custom SELINUXpolicy package
sudo semodule -i zabbix_policy.pp

#step 8
#Perform an upgrade
sudo dnf upgrade 'zabbix-*'
sudo systemctl restart zabbix-server
