#!/bin/bash

# Оновлення індексу пакетів
sudo apt-get update

# Встановлення MySQL
sudo apt-get install -y mysql-server

# Налаштування MySQL
sudo mysql -e "CREATE DATABASE hillelDB;"
sudo mysql -e "CREATE USER 'admindb'@'localhost' IDENTIFIED BY 'test123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON hillelDB.* TO 'admindb'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
