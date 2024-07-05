#!/bin/bash

# Встановити профіль AWS CLI
export AWS_PROFILE="default"

# Опис ваших інстансів
INSTANCE_WITH_PUBLIC_IP="i-0f4acc4a71b58d01b"
INSTANCE_WITH_PRIVATE_IP="i-0493b405702c7e69b"
DB_HOST_ALIAS="db-host"
JUMP_HOST_ALIAS="front"

# Файл конфігурації SSH
SSH_CONFIG="$HOME/.ssh/config"

# Тимчасовий файл для нового конфігу
TEMP_CONFIG="$SSH_CONFIG.tmp"

# Функція для отримання публічної IP-адреси
get_public_ip() {
  local instance_id=$1
  aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text
}

# Функція для отримання приватної IP-адреси
get_private_ip() {
  local instance_id=$1
  aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text
}

# Отримання IP-адрес інстансів
PUBLIC_IP=$(get_public_ip $INSTANCE_WITH_PUBLIC_IP)
PRIVATE_IP=$(get_private_ip $INSTANCE_WITH_PRIVATE_IP)

# Перевірка отримання IP-адрес
if [ -z "$PUBLIC_IP" ]; then
  echo "Не вдалося отримати публічну IP-адресу для інстанса $INSTANCE_WITH_PUBLIC_IP"
  exit 1
fi

if [ -z "$PRIVATE_IP" ]; then
  echo "Не вдалося отримати приватну IP-адресу для інстанса $INSTANCE_WITH_PRIVATE_IP"
  exit 1
fi

# Створення нового конфігу SSH
echo "" > $TEMP_CONFIG

# Додавання запису для інстанса з публічною IP-адресою
echo "Host $JUMP_HOST_ALIAS" >> $TEMP_CONFIG
echo "  HostName $PUBLIC_IP" >> $TEMP_CONFIG
echo "  User ubuntu" >> $TEMP_CONFIG
echo "  IdentityFile ~/.ssh/web-key.pem" >> $TEMP_CONFIG
echo "" >> $TEMP_CONFIG

# Додавання запису для інстанса з приватною IP-адресою
echo "Host $DB_HOST_ALIAS" >> $TEMP_CONFIG
echo "  HostName $PRIVATE_IP" >> $TEMP_CONFIG
echo "  User ubuntu" >> $TEMP_CONFIG
echo "  IdentityFile ~/.ssh/back-key.pem" >> $TEMP_CONFIG
echo "  ProxyJump $JUMP_HOST_ALIAS" >> $TEMP_CONFIG

echo "" >> $TEMP_CONFIG

# Переміщення нового конфігу на місце старого
mv $TEMP_CONFIG $SSH_CONFIG

echo "Конфігурація SSH оновлена!"
