#!/bin/bash
######################################################################################################
### Author: Sidney Omondi
### Version: v1.3.0
### Date: 2021-5-24 [YYY-MM-DD]
### Description:
###           Script aims to automate installation of Zabbix on CentOS
###
### Usage: ./Zabbix_install.sh
######################################################################################################
source $(dirname $0)/lib/functions.sh
initialize_colors
zabbix_config_file="/etc/zabbix/zabbix_server.conf"
zabbix_php_file="/etc/php-fpm.d/zabbix.conf"
filename=$(basename $0)
ip_addr=$(ifconfig | grep "inet" | grep "broadcast" | awk '{print $2}') #get IP address of the machine

function check(){
  local OPTIND opt i
    no_args="true"
      while getopts "ihO" opt; do
      case "$opt" in
        i) animate_banner && installation_function
        ;;
        O) optimization_function
        ;;
        h) usage $filename
        exit 0
        ;;
        \?) usage $filename;  exit 1

        ;;

      esac
      no_args="false"
    done
    [[ "$no_args" == "true" ]] && { usage $filename; exit 1; }

    shift $(( OPTIND -1 ))

}
install_dependencies(){
  #step 1
  #Set SELinux to work in permissive mode
  sudo setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
  #Step2
  # Install Zabbix Server, frontend and agent
  rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
  sudo dnf clean all
  sudo dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent
}

install_DB(){
  #Step3
  #Install and configure DB
  # a) install MariaDB
  sudo dnf -y install mariadb-server && sudo systemctl start mariadb && sudo systemctl enable mariadb
}
returnConfirmedPassword(){
	while true;do
		 stty -echo
		read -p "Enter a password for your zabbix user [zabbix] : "  zabbixDBpass
		echo
		read -p "Confirm Entered Password " Confirm
		echo
		stty echo
		confirmPass $ zabbixDBpass $Confirm
		response=$?

		if [[ "$response" -eq 0 ]]
		then
			break
		else
			 echo "Passwords DONT match please try Again"
			 echo
		fi
	done
}


# b) change root password
change_MYSQ_rootPWD(){
  mysql_secure_installation #run as final stage
}

# c) Create database

configure_mysql_db(){
  sudo mysql  --execute="
  CREATE DATABASE zabbix character set utf8 collate utf8_bin;
  grant all privileges on zabbix.* to zabbix@localhost identified by '${zabbixDBpass}';
  USE zabbix
  SET global innodb_strict_mode='OFF';
  "
}

#enable strict mode
edit_config_files(){
  sudo mysql --execute="USE zabbix;
  SET global innodb_strict_mode='ON';
  "
  sed -i "/^DBPassword=/ s/DBPassword=/DBPassword=$zabbixDBpass/ " "${zabbix_config_file}"
  sleep 0.1
}

start_server(){
  #Step4
  #Start Zabbix server and Agent Process
  sudo systemctl restart zabbix-server zabbix-agent
  sudo systemctl enable zabbix-server zabbix-agent

  #Step5
  #Configure firewall
  sudo firewall-cmd --add-service={http,https} --permanent
  sudo firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
  sudo firewall-cmd --reload
}
zabbix_frontend(){
  #Step 6
  # a) configure Zabbix frontend
  sed -i "/^ /; php_value date.timezone Europe\/Riga/ s/; php_value date.timezone Europe\/Riga/php_value date.timezone Africa\/Nairobi/" "${zabbix_php_file}"

  # b) Restart Apache Services
  sudo systemctl restart httpd php-fpm
  sudo systemctl enable httpd php-fpm
}

# c) Configure web frontend
final_step(){
  echo -e "visit ${yellow_color}http://${ip_addr}/zabbix ${normal_color}to complete installation
  Enter your DB Password and continue with ${BCyan}NEXT${normal_color}

  and finally use default credentials , ${green_color}Admin ${normal_color}and ${green_color}Zabbix${normal_color} to login
  "
}

# d ) Optimization
optimize_zabbix(){
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

}
optimize_mysql(){
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
}


enableAndConfigureSELinux(){

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

}
installation_function(){
  #step 1 & 2
  install_dependencies
    #step 3
    install_DB
      #step (4 a)
      returnConfirmedPassword
        #step (4 b)
        configure_mysql_db
          #step 5
          # d) Import initial schema and data
            yum install pv &&
            mysql_import_function /usr/share/doc/zabbix-server-mysql*/create.sql.gz zabbix $zabbixDBpass zabbix
              #step 6
              edit_config_files
                #step 7
                start_server
                zabbix_frontend
                  #step
                  final_step
                  sleep 0.2 && change_MYSQ_rootPWD
}

optimization_function(){
  optimize_zabbix
  optimize_mysql

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

}
check $@
