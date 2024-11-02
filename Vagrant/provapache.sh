#!/bin/bash
sudo apt update
sudo apt install apache2 -y
sudo apt install php libapache2-mod-php php-mysql -y
sudo systemctl restart apache2
cd /var/www/html
sudo mkdir GestAlumnos
cd GestAlumnos
sudo git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
sudo mv iaw-practica-lamp/* .
sudo rm  -r iaw-practica-lamp/
sudo rm -r db/
sudo rm README*
sudo rm /var/www/html/index.html
sudo a2dissite 000-default.conf
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/gestalumnos.conf
cat <<EOL > /etc/apache2/sites-available/gestalumnos.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/GestAlumnos/src

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combine
</VirtualHost>
EOL
cat <<EOL > /var/www/html/GestAlumnos/src/config.php
<?php

define('DB_HOST', '172.31.1.11');
define('DB_NAME', 'lamp_db');
define('DB_USER', 'lamp_user');
define('DB_PASSWORD', '1234-Lamp');

\$mysqli = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

?>
EOL
#sudo chmod -R 755 /var/www/html/GestAlumnos/
#sudo chown -R www-data:www-data /var/www/html/GestAlumnos/
sudo a2ensite gestalumnos.conf
sudo systemctl restart apache2
