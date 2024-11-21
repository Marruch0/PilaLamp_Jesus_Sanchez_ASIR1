# Trabajo Pila Lamp

# Índice

1. [Creación de VagrantFile](#creación-de-vagrantfile)
2. [Creación de provision Apache](#creación-de-provision-apache)
   - [Instalación manual Apache2](#instalación-manual-apache2)
3. [Creación de provision MySQL](#creación-de-provision-mysql)
   - [Instalación manual MySQL](#instalación-manual-mysql)
4. [Comprobación del funcionamiento](#comprobación-del-funcionamiento)

# Creación de VagrantFile

Para crear un vagrant file primero que nada nos situaremos en el directorio que queramos usar, lo recomendable es crear uno nuevo y trabajar en él. En mi caso crearé y trabajaré en uno llamado `PilaLamp`

Para crearlo ejecutamos el comando `mkdir nombre` 

Una vez creado nos entramos dentro de un directorio sino tenemos instalado vagrant lo instalaremos primero, yo lo he instalado en Fedora ya que es el sistema operativo que uso. Para instalarlo ejecutamos los siguientes comandos:

- `sudo dnf install -y dnf-plugins-core`
- `sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo`
- `sudo dnf -y install vagrant`

Una vez instalado y situados en la carpeta ejecutamos `vagrant init` para crear el fichero de configuración.

Una vez creado añadiremos las siguientes lineas:

```bash
Vagrant.configure("2") do |config|

   config.vm.box = "ubuntu/jammy64"
   config.vm.define "JesusSanApache" do |apache|
	   apache.vm.hostname = "JesusSanApache"
	   apache.vm.network "forwarded_port", guest:80, host: 8080
     apache.vm.network "public_network"
	   apache.vm.network "private_network", ip: "172.31.1.10", virtualbox__intnet: "redserver"
	   apache.vm.provision "shell", path: "provapache.sh"

   end

   config.vm.define "JesusSanMysql" do |sql|
	   sql.vm.hostname = "JesusSanMysql"
	   sql.vm.network "public_network"
	   sql.vm.network "private_network", ip: "172.31.1.11", virtualbox__intnet: "redserver"
	   sql.vm.provision "shell", path: "provmysql.sh"
   end
```

Ahora ejecutamos `vagrant up` para comprobar que todo funciona.

Una vez que hemos comprobado que funciona vamos a realizar el provisión para automatizar todo.

# Creación de provision Apache

```bash
#!/bin/bash
# Actualiza la lista de paquetes disponibles
sudo apt update
# Instala el servidor web Apache
sudo apt install apache2 -y
# Instala PHP y el módulo para Apache para interpretar PHP
sudo apt install php libapache2-mod-php php-mysql -y
# Reinicia el servicio Apache para aplicar los cambios
sudo systemctl restart apache2
# Cambia al directorio raíz de los archivos web
cd /var/www/html
# Crea un nuevo directorio para la aplicación GestAlumnos
sudo mkdir GestAlumnos
# Entra en el directorio GestAlumnos
cd GestAlumnos
# Clona el repositorio de la práctica LAMP en el directorio actual
sudo git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
# Mueve todos los archivos del repositorio clonado al directorio actual
sudo mv iaw-practica-lamp/* .
# Elimina el directorio del repositorio clonado ya que ya no es necesario
sudo rm  -r iaw-practica-lamp/
# Elimina el directorio 'db' que no es necesario para el despliegue
sudo rm -r db/
# Elimina cualquier archivo README que no sea necesario
sudo rm README*
# Elimina la página de inicio predeterminada de Apache
sudo rm /var/www/html/index.html
# Deshabilita el sitio por defecto de Apache
sudo a2dissite 000-default.conf
# Copia la configuración del sitio por defecto para crear una nueva configuración para GestAlumnos
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/gestalumnos.conf
# Sobrescribe el archivo de configuración del nuevo sitio con la configuración específica para GestAlumnos
# Se usa EOL pero se podria utilizar cualquiera palabra que tenga un principio y luego al final
cat <<EOL > /etc/apache2/sites-available/gestalumnos.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/GestAlumnos/src

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combine
</VirtualHost>
EOL
# Crea el archivo de configuración de la base de datos para la aplicación
cat <<EOL > /var/www/html/GestAlumnos/src/config.php
<?php

define('DB_HOST', '172.31.1.11');
define('DB_NAME', 'lamp_db');
define('DB_USER', 'lamp_user');
define('DB_PASSWORD', '1234-Lamp');

\$mysqli = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

?>
EOL
# Opcional: Establecer permisos para los archivos y cambiar el propietario al usuario de Apache
#sudo chmod -R 755 /var/www/GestAlumnos/
#sudo chown -R www-data:www-data /var/www/GestAlumnos/
# Habilita el sitio GestAlumnos en Apache
sudo a2ensite gestalumnos.conf
# Reinicia Apache para aplicar la nueva configuración
sudo systemctl restart apache2
```

## Instalación manual Apache2

El anterior script para el provisión nos permite levantar la maquina totalmente operativa y funcional, sin embargo es importante saber que hace y porque lo estamos haciendo. Por lo tanto voy a explicar como sería una configuración manual.

Una vez que hemos hecho el `vagrant up` nos conectamos a la maquina por ssh, vagrant permite hacerlo de manera muy sencilla. Simplemente ejecutamos el comando → `vagrant ssh nombre` en nombre pondremos el nombre que le hemos puesto a la maquina de apache, en mi caso se llama JesusSanApache, por lo tanto quedaría así `vagrant ssh JesusSanApache.`

Una vez que estamos conectados a la maquina lo primero que haremos será actualizar los paquetes y librerías con `sudo apt update`.

Una vez actualizado instalaremos apache usando el comando `sudo apt install apache2 -y`

Después de tener apache2 instalado vamos instalar php y los módulos correspondientes para conectar apache2 y mysql con php. Esto lo haremos ejecutando el comando `sudo apt install php libapache2-mod-php php-mysql -y`

Una vez instalado nos iremos con `cd` a la ruta `/var/www/html` la cual es la ruta por defecto donde estarán alojados el codigo y los configuraciones de la página. Ahora vamos a crear un directorio que será donde vamos a instalar nuestra pagina, en mi caso la he llamado `GestAlumnos`

Nos entramos en el directorio con `cd` y descargamos con `git clone` el siguiente enlace:

https://github.com/josejuansanchez/iaw-practica-lamp.git

Ahora moveremos todo lo que hay dentro al directorio actual y eliminaremos lo que no necesitamos con:

- `sudo mv iaw-practica-lamp/* .`
- `sudo rm  -r iaw-practica-lamp/`
- `sudo rm -r db/`
- `sudo rm README*`
- `sudo rm /var/www/html/index.html`

Una vez que hemos eliminado lo que no necesitamos nos vamos a ir a ir al directorio de configuración de apache que esta en la ruta `/etc/apache2` y dentro de aquí nos iremos a `sites-avaliable`, dentro de este directorio lo que encontramos son los sitios que están disponibles pero no habilitados por lo que podemos aprovechar eso y copiar el sitio por defecto para crear nosotros uno nuevo. 

Copiamos el fichero de configuración y lo renombramos con `sudo cp 000-default.conf gestalumnos`

Ahora lo editaremos con nano, cuando lo abrimos nos encontramos algo como esto:

```bash
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combine
</VirtualHost>
```

Veremos que la ruta que viene por defecto está apuntado a html y la nuestra tendrá que apuntar al directorio que hemos creado y al directorio donde se encuentra todo que seria `/GestAlumnos/src`

Por ello el fichero editado quedaría así:

```bash
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/GestAlumnos/src

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combine
</VirtualHost>
```

Ahora en el directorio de src concretamente en `/var/www/html/GestAlumnos/src`, encontraremos un fichero llamado `config.php`, dentro de este definiremos el host de la base de datos(IP del servidor mysql), el nombre, el usuario y su contraseña. En mi caso el fichero quedará así:

```php
<?php

define('DB_HOST', '172.31.1.11');
define('DB_NAME', 'lamp_db');
define('DB_USER', 'lamp_user');
define('DB_PASSWORD', '1234-Lamp');

'$mysqli' = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

?>
```

—Punto importante— Si lo vamos añadir para el provision importante que en `'$mysqli'` habría que añadir una barra invertida, así: `\'$mysqli'` para que a la hora de ejecutarlo el provision no lo tome como una variable ya que sino no lo pondrá en el fichero.

Guardamos el fichero y habilitamos el sitio con → `sudo a2ensite gestalumnos.conf`

Ahora reiniciaremos apache2 para que se ejecuten las nuevas modificaciones:

`sudo systemctl restart apache2`

Con esto ya habríamos acabo la parte de apache2.

Ahora pasaremos a configurar Mysql.

# Creación de provision Mysql

```bash
#!/bin/bash
# Actualiza la lista de paquetes disponibles
sudo apt update
# Instala el servidor MySQL
sudo apt install mysql-server -y
# Clona el repositorio de la práctica LAMP
sudo git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
# Mueve los archivos del repositorio al directorio actual
sudo mv iaw-practica-lamp/* .
# Elimina el directorio clonado ya que los archivos se han movido
sudo rm  -r iaw-practica-lamp/
# Elimina el directorio 'src/' (si existe)
sudo rm -r src/
# Elimina los archivos README* (si existen)
sudo rm README*
# Cambia al directorio 'db/' que contiene el archivo de la base de datos
cd db/
# Cambia al usuario root para ejecutar los comandos MySQL
sudo su
# Carga la base de datos desde el archivo SQL usando MySQL
mysql -u root < database.sql
# Crea un usuario para la base de datos y le otorga privilegios
mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'lamp_user'@'172.31.1.10' IDENTIFIED BY '1234-Lamp';
GRANT ALL PRIVILEGES ON lamp_db.* TO 'lamp_user'@'172.31.1.10';
FLUSH PRIVILEGES;
EOF
# Cambia laconfiguración de MySQL para permitir conexiones desde una IP específica
sed -i 's/^bind-address.*/bind-address = 172.31.1.11/' /etc/mysql/mysql.conf.d/mysqld.cnf
# Reinicia el servicio MySQL para aplicar los cambios de configuración
sudo systemctl restart mysql
# Elimina la ruta por defecto del sistema 
sudo ip route del default
```

## Instalación manual Mysql

Primero que nada nos conectaremos por ssh a la maquina, para ello como hemos hecho con el servidor de apache2 haremos `vagrant ssh` y el nombre que en mi caso es `JesusSanMysql`

Una vez estamos conectados a la maquina haremos un `sudo apt update` para actualizar las librerías.

Ahora instalaremos mysql-server con `sudo apt install mysql-server -y`

Una vez instalado pasaremos a descargar los repositorios como en el apache:

`sudo git clone https://github.com/josejuansanchez/iaw-practica-lamp.git`

Ahora borraremos todo menos la base de datos con:

- `sudo rm  -r iaw-practica-lamp/`
- `sudo rm -r src/`
- `sudo rm README*`

Ahora nos entraremos en el directorio llamado `db` y allí encontraremos un fichero de nombre `database.sql` cuyo contenido es el siguiente:

```php
DROP DATABASE IF EXISTS lamp_db;
CREATE DATABASE lamp_db CHARSET utf8mb4;
USE lamp_db;

-- Create the users table
CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  age INT UNSIGNED NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

Aquí encontraremos un script de creación de la base de datos, para poder crear usando la base de datos usando el .sql, elevamos privilegios como root con `sudo su` y ejecutamos el siguiente comando: `mysql -u root < database.sql`

Ahora para asegurarnos de que funciona nos entraremos a la base de datos como root con `mysql -u root`. Una vez que estamos dentro de mysql  podemos comprobar que la base de datos está haciendo `show databases;`, si el script se ejecutó bien ahora deberíamos de tener una base de datos llamada lamp_db.

Ahora vamos a crear un usuario y a darles privilegios, este usuario es el que usuraremos para poder conectar la base de datos y apache, que es el que hemos añadido en el `config.php` anteriormente.

Para ello primero creamos el usuario con:

`CREATE USER IF NOT EXISTS 'lamp_user'@'172.31.1.10' IDENTIFIED BY '1234-Lamp';`

Si nos fijamos la ip que le ponemos es la ip del servidor de apache y no la del servidor de mysql, mucho cuidado con eso.

Ahora le daremos los permisos necesarios con:

`GRANT ALL PRIVILEGES ON lamp_db.* TO 'lamp_user'@'172.31.1.10';`

Y aplicamos los permisos con:

`FLUSH PRIVILEGES;`

Ahora tendremos que editar en el fichero `mysqld.cnf` la ip del `bind-address`, aquí le tendremos que indicar la ip del servidor mysql, en mi caso es `172.31.1.11`.

La ruta donde esta este fichero es `/etc/mysql/mysql.conf.d/mysqld.cnf` mucho ojo ya que hay dos archivos uno acabado en d y otro no, tenemos que editar el que acaba en d.

Ahora lo ultimo que quedaría es reiniciar mysql con `sudo systemctl restart mysql` y para una mejor seguridad le quitaremos la puerta de enlace de la nat para que no tenga salida a internet, esto lo haremos con `sudo ip route del default`

# Comprobación del funcionamiento
![imagen](https://github.com/user-attachments/assets/0e522d4d-bb8a-451a-9f0c-555a8e77173a)
![imagen 1](https://github.com/user-attachments/assets/da7fc657-d82c-4c83-b720-957ae269ac51)
![imagen 2](https://github.com/user-attachments/assets/cfdc9740-d873-4359-8b23-6c66a59588f5)
![imagen 3](https://github.com/user-attachments/assets/550d7c16-8544-4f1e-aa9f-75ea7f0f31db)
![imagen 4](https://github.com/user-attachments/assets/f1059641-46fe-48f6-aa3d-c42097bf22c5)
![imagen 5](https://github.com/user-attachments/assets/5f302366-b0e2-434e-8a4b-752efde34a43)
![imagen 6](https://github.com/user-attachments/assets/69caa5d0-452f-477e-bf3e-059cfdeb67ae)
![ee122e0d-bbb8-4667-8251-d72976ffd0c8](https://github.com/user-attachments/assets/d7dbda69-1969-40fc-adae-7224b478cb53)






