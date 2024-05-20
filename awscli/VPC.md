### create key pair with cli

aws ec2 create-key-pair --key-name web-test-key --key-type ed25519 --key-format pem --query "KeyMaterial" --output text > web-test-key.pem


# create ec-2

## 1st create Public ec2 and create the mariadb on it:
### Frontend-devops, default ami with ubuntu:

aws ec2 run-instances \
    --image-id ami-023adaba598e661ac \
    --count 1 \
    --instance-type t2.micro \
    --key-name web-key \
    --security-group-ids sg-00072bba1a5bec5cd \
    --subnet-id subnet-060113e650ffd523a \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=FRONT},{Key=Environment,Value=DEV}]' 

## mariiadb: 

#!/bin/bash

### Update package index
sudo apt-get update
### Install MariaDB
sudo apt-get install mariadb-server -y
### Start MariaDB service
sudo systemctl start mariadb
## Enable MariaDB to start on boot
sudo systemctl enable mariadb
# Set root password for MariaDB 
sudo mysqladmin -u root password 'test123'
# Create a new database (replace 'your_database' with your desired database name)
sudo mysql -u root -p'test123' -e "CREATE DATABASE hillelDB;"
# Create a new user
sudo mysql -u root -p'test123' -e "CREATE USER 'admindb'@'localhost' IDENTIFIED BY 'test123';"
# Grant privileges to the new user for the new database
sudo mysql -u root -p'test123' -e "GRANT ALL PRIVILEGES ON hillelDB.* TO 'admindb'@'localhost';"
# Flush privileges
sudo mysql -u root -p'test123' -e "FLUSH PRIVILEGES;"
# Restart MariaDB service
sudo systemctl restart mariadb

sudo systemctl status mariadb
sudo bash -c 'echo "[mysqld]" >> /etc/mysql/my.cnf'
sudo bash -c 'echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf'
mysql -u admindb -p


# create the ami from ec2

aws ec2 create-image \
    --instance-id i-0e88a859c6a65448a \
    --name "hilleldb" \
    --description "An AMI for mariaDB, hillelDB installed"

# result: 
{
    "ImageId": "ami-06169a18dd1f8e0da"
}

## my ami's
aws ec2 describe-images --owners 872907144139 --query "Images[].{ImageId:ImageId, Name:Name}" --output table


# private - with mariaDB: 
aws ec2 run-instances \
    --image-id ami-06169a18dd1f8e0da \
    --count 1 \
    --instance-type t2.micro \
    --key-name back-key \
    --security-group-ids sg-033bca410efb8eac6 \
    --subnet-id subnet-0761d72f5fdf9b6e2 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DB},{Key=Environment,Value=DEV}]'


# Create NEW Front again.

aws ec2 run-instances \
    --image-id ami-023adaba598e661ac \
    --count 1 \
    --instance-type t2.micro \
    --key-name web-key \
    --security-group-ids sg-00072bba1a5bec5cd \
    --subnet-id subnet-060113e650ffd523a \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=FRONT},{Key=Environment,Value=DEV}]' 

## task: connect with ssh db-host

# прописати по хостах в конфіг at local .ssh

Host front
  Hostname 18.194.207.250
  User ubuntu
  IdentityFile ~/.ssh/web-key.pem

Host db-host
  Hostname 10.0.8.180
  User ubuntu
  IdentityFile ~/.ssh/back-key.pem
  ProxyJump front
