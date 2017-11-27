#!/bin/bash

usage() {
/bin/cat <<EOF
Usage: $0 "Site Name"
	Please enter the name of the site as a variable after the script name
EOF
}

#  Enter varibles needed for mysql config
read -s -p "Enter your mysql root password:"$'\n' dbRootPass
read -p "Enter the new database name:" dbName
read -p "Enter the new username:" userName
read -s -p "Enter the new user's password:"$'\n' userPass

#  Check to make sure the site name was entered with the script

if [ -z "$1" ]; then
	usage
	exit 0
else
	siteName=$1
	/bin/echo "The sitename is $siteName"
fi

#  Create new repo for MariaDB

if [ ! -f /etc/yum.repos.d/MariaDB.repo ]; then
	/bin/echo "
# MariaDB 10.1 CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/

[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
	" > /etc/yum.repos.d/MariaDB.repo
	/bin/echo "/etc/yum.repos.d/MariaDB.repo created"
else
	/bin/echo "MariaDB.repo already exists"
fi

#  Install Yum packages
#  Will check whether the package in packageList exists on the system and will install if not

packageList="
httpd
wget
rsync
MariaDB-server
MariaDB-client
php
php-common
php-gd
php-mysql
php-xml
php-mbstring
php-mcrypt
php-xmlrpc
php-mysql
policycoreutils-python
setroubleshoot-server
"

for package in $packageList
do
	if /usr/bin/rpm -qa | grep -q ^"$package" ; then
		/usr/bin/echo "$package" is already installed
	else
		/usr/bin/echo "$package" is not installed yet
		yum -y install "$package"
	fi
done

#  Make the directories

dirList="
	"$siteName"
	logs
	cache
"

for dir in $dirList; do
	if [ ! -d /var/www/html/"$dir" ]; then	
		/bin/mkdir /var/www/html/"$dir"
		/bin/echo "Created /var/www/html/$dir"
	else
		/bin/echo "$dir exists"

	fi
done

#  Create the Virtual Hosts

if [ ! -f /etc/httpd/conf.d/"$siteName".conf ]; then
	/bin/echo "
NameVirtualHost *:80

<VirtualHost *:80>
    ServerAdmin webmaster@"$siteName".com
    ServerName "$siteName".com
    ServerAlias www."$siteName".com
    DocumentRoot /var/www/html/"$siteName"
    ErrorLog /var/www/html/logs/"$siteName"_error.log
    CustomLog /var/www/html/logs/"$siteName"_access.log combined
</VirtualHost>
	" > /etc/httpd/conf.d/"$siteName".conf
	/bin/echo "File /etc/httpd/conf.d/"$siteName".conf created"
else
	/bin/echo "File /etc/httpd/conf.d/"$siteName".conf already in use"
	/bin/cat /etc/httpd/conf.d/"$siteName".conf
fi

#  Basic configuration of firewall

firewall-cmd --add-service=http --permanent && sudo firewall-cmd --add-service=https --permanent
systemctl restart firewalld

#  Enable and start the MariaDB service

/bin/systemctl start mariadb.service
/bin/systemctl enable mariadb.service

#  Automate the mysql secure installation script. Based on http://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/ Thank you Bert Van Vreckem!


if ! mysqladmin --user=root status &> /dev/null; then
	/bin/echo "Mysql root password already set. Please secure manually."
else
	/bin/mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('$dbRootPass') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_
fi

#  Create the database, user and user password

/bin/mysql -u root -p"$dbRootPass"<<_EOF_
CREATE DATABASE $dbName;
CREATE USER $userName@localhost IDENTIFIED BY '$userPass';
GRANT ALL PRIVILEGES ON $dbName.* TO $userName@localhost IDENTIFIED BY '$userPass';
FLUSH PRIVILEGES;
exit
_EOF_

#  Download and configure Wordpress

/bin/systemctl restart httpd.service

/bin/wget http://wordpress.org/latest.tar.gz /home/"$SUDO_USER"/
/bin/tar xzvf /home/"$SUDO_USER"/latest.tar.gz

/bin/rsync -avP /home/"$SUDO_USER"/wordpress/ /var/www/html/"$siteName"
/bin/chown -R apache:apache /var/www/html/"$siteName"
/bin/cp /var/www/html/"$siteName"/wp-config-sample.php /var/www/html/"$siteName"/wp-config.php

/bin/find  /var/www/html/"$siteName" -type d -exec chmod 755 {} \;
/bin/find  /var/www/html/"$siteName" -type f -exec chmod 644 {} \;

sed -i "s:database_name_here:${dbName}:; s:username_here:${userName}:; s:password_here:${userPass}:" /var/www/html/"$siteName"/wp-config.php
sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf

/bin/rm -f /home/"$SUDO_USER"/latest.tar.gz 
/bin/rm -r -f /home/"$SUDO_USER"/wordpress

#  Set Selinux permissions and restorecon

/sbin/semanage fcontext -a -t httpd_sys_content_t "/var//www/html(/.*)?"
/sbin/semanage fcontext -a -t httpd_log_t "/var/www/html/logs(/.*)?"
/sbin/semanage fcontext -a -t httpd_cache_t "/var/www/html/cache(/.*)?"

/sbin/restorecon -Rv /var/www .*
/bin/systemctl restart httpd.service

