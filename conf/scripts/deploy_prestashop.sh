#!/bin/bash
# Instala y configura PrestaShop en /var/www/html
set -ex

cd "$(dirname "$0")"
source .env

export DEBIAN_FRONTEND=noninteractive

# Extensiones de PHP y herramientas necesarias
apt update
apt install -y unzip curl php-curl php-gd php-intl php-mbstring php-xml php-zip php-bcmath php-mysql

# Módulos de Apache recomendados por PrestaShop
a2enmod rewrite headers

# Ajustes del php.ini de Apache
PHP_INI=$(ls /etc/php/*/apache2/php.ini)
sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHP_INI
sed -i 's/^post_max_size.*/post_max_size = 128M/' $PHP_INI
sed -i 's/^upload_max_filesize.*/upload_max_filesize = 128M/' $PHP_INI
sed -i 's/^;*max_input_vars.*/max_input_vars = 5000/' $PHP_INI
systemctl restart apache2

# Descargar PrestaShop (-f hace que falle si la URL no existe)
rm -rf /tmp/ps /tmp/prestashop.zip
mkdir /tmp/ps
curl -fL -o /tmp/prestashop.zip "$PS_URL"
unzip -tq /tmp/prestashop.zip
unzip -q /tmp/prestashop.zip -d /tmp/ps

# Limpiar /var/www/html (se conserva phppsinfo.php) y copiar PrestaShop
find /var/www/html -mindepth 1 -maxdepth 1 ! -name phppsinfo.php -exec rm -rf {} +
if [ -f /tmp/ps/prestashop.zip ]; then
  # El zip oficial trae dentro otro zip con la tienda
  unzip -q /tmp/ps/prestashop.zip -d /var/www/html
else
  cp -a /tmp/ps/. /var/www/html/
fi
chown -R www-data:www-data /var/www/html

# Base de datos
mysql -u root <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Instalación de PrestaShop desde la línea de comandos
cd /var/www/html/install
sudo -u www-data php index_cli.php \
  --domain=$DOMAIN \
  --db_server=localhost \
  --db_name=$DB_NAME \
  --db_user=$DB_USER \
  --db_password=$DB_PASSWORD \
  --email=$ADMIN_EMAIL \
  --password=$ADMIN_PASSWORD \
  --language=es \
  --country=es \
  --ssl=1 \
  --newsletter=0 \
  --send_email=0

# Borrar la carpeta install (obligatorio por seguridad)
rm -rf /var/www/html/install
chown -R www-data:www-data /var/www/html
