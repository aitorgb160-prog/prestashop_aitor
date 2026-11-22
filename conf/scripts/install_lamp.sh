#!/bin/bash
# Instala Apache, MySQL, PHP y phpMyAdmin
set -ex

# Ir a la carpeta del script para poder leer el .env
cd "$(dirname "$0")"
source .env

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

apt update
apt upgrade -y

# Apache, MySQL y PHP
apt install -y apache2
apt install -y mysql-server
apt install -y php libapache2-mod-php php-mysql

# phpMyAdmin (instalación sin preguntas)
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt install -y phpmyadmin php-mbstring php-zip php-gd php-curl

# Usuario administrador de MySQL para entrar en phpMyAdmin
mysql -u root <<EOF
CREATE USER IF NOT EXISTS '$MYSQL_ADMIN_USER'@'localhost' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_ADMIN_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf
sed -i "s/DOMINIO_AQUI/$DOMAIN/" /etc/apache2/sites-available/000-default.conf
a2enmod rewrite
systemctl restart apache2
