#!/bin/bash
sudo apt update
sudo apt install mysql-server -y
sudo git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
sudo mv iaw-practica-lamp/* .
sudo rm  -r iaw-practica-lamp/
sudo rm -r src/
sudo rm README*
cd db/
sudo su
mysql -u root < database.sql
mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'lamp_user'@'172.31.1.10' IDENTIFIED BY '1234-Lamp';
GRANT ALL PRIVILEGES ON lamp_db.* TO 'lamp_user'@'172.31.1.10';
FLUSH PRIVILEGES;
EOF
sed -i 's/^bind-address.*/bind-address = 172.31.1.11/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql
sudo ip route del default
