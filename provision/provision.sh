#!/bin/bash

apt-get update
apt-get install python-software-properties --assume-yes
add-apt-repository ppa:ondrej/php
# Add apt repository mariadb 10.1[Stable]
sudo apt-get install python-software-properties
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
sudo add-apt-repository 'deb [arch=amd64,i386] http://ca.mirror.babylon.network/mariadb/repo/10.1/ubuntu precise main'
apt-get update

# Configurations

PACKAGES="php5.6 mysql-client mariadb-server php5.6-mysql apache2 tree vim curl git"
PACKAGES="$PACKAGES nginx-full php5.6-fpm php5.6-cgi spawn-fcgi php-pear php5.6-mcrypt "
PACKAGES="$PACKAGES php5.6-mbstring php5.6-curl php5.6-cli php5.6-gd php5.6-intl"
PACKAGES="$PACKAGES php5.6-xsl php5.6-zip fcgiwrap phpmyadmin"

PUBLIC_DIRECTORY="/home/vagrant/public_www"
DATABASE_DIRECTORY="/home/vagrant/database"
CHUY_DIRECTORY="/home/vagrant/chuy"

# Sets mysql pasword
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'

# Sets configuration phpmyadmin pasword
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password password"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password password"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password password"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"

echo "Installing packages $PACKAGES ..."

apt-get install $PACKAGES --assume-yes

# Makes apache not init in start
update-rc.d -f  apache2 remove
update-rc.d php5.6-fpm defaults

# Public folder
if [ ! -d "$PUBLIC_DIRECTORY" ]; then
    mkdir $PUBLIC_DIRECTORY
fi
# database folder
if [ ! -d "$DATABASE_DIRECTORY" ]; then
    mkdir $DATABASE_DIRECTORY
fi
# chuy folder
if [ ! -d "$CHUY_DIRECTORY" ]; then
    mkdir $CHUY_DIRECTORY
fi


# Installing composer
curl -sS https://getcomposer.org/installer | php
chmod +x composer.phar
mv composer.phar /usr/local/bin/composer

# Generates unique token for application
if [ ! -f "$APP_TOKEN" ]; then
:    touch $APP_TOKEN
    echo $RANDOM > $APP_TOKEN
fi

# Create a symbolic link from the installation phpmyadmin
sudo ln -s /usr/share/phpmyadmin /home/vagrant/chuy

# Activates site

## Apache
cp /home/vagrant/templates/chuy.apache /etc/apache2/sites-available/chuy
cp /home/vagrant/templates/default.apache /etc/apache2/sites-available/site
cp /home/vagrant/templates/httpd.conf /etc/apache2/conf.d/httpd.conf
rm  /etc/apache2/sites-enabled/*
ln -s /etc/apache2/sites-available/chuy /etc/apache2/sites-enabled/
a2enmod actions
a2dissite default
a2ensite default
service apache2 stop

## Nginx
cp /home/vagrant/templates/chuy.nginx /etc/nginx/sites-available/chuy
cp /home/vagrant/templates/default.nginx /etc/nginx/sites-available/site
cp /home/vagrant/templates/www.conf /etc/php5.6/fpm/pool.d/www.conf
cp /home/vagrant/templates/nginx.conf /etc/nginx/nginx.conf
cp /home/vagrant/templates/nginx.conf /home/vagrant/nginx.conf
rm  /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/site /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/chuy /etc/nginx/sites-enabled/
service php5.6-fpm restart
service nginx restart

# Mysql create user chuy
mysql -u"root" -p"password" -e "CREATE USER 'chuy'@'localhost' IDENTIFIED BY 'password'"
mysql -u"root" -p"password" -e "GRANT ALL PRIVILEGES ON * . * TO 'chuy'@'localhost' WITH GRANT OPTION"

