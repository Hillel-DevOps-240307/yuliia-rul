
## intro
### Перелік використаних змінних
- `/demo/app/ext_port` 
- `/demo/db/MYSQL_PASS`
- `/demo/db/MYSQL_USER`
- `/demo/db/priv_ip`

tag 'task' value 3

- aws iam tag-instance-profile --instance-profile-name DbRole --tags '[{"Key": "task", "Value
": "3"}]'
- aws iam tag-instance-profile --instance-profile-name AppRole --tags '[{"Key": "task", "Value
": "3"}]'
- aws iam list-instance-profile-tags --instance-profile-name "DbRole"
- aws iam list-instance-profile-tags --instance-profile-name "AppRole"
	```markdown
	# result

	```json
	{
		"Tags": [
			{
				"Key": "task",
				"Value": "3"
			}
		],
		"IsTruncated": false
	}
	```
<details>
	<summary>Policy <b>access-to-ssm-parameters</b></summary>
	```markdown
	# policy

	```json
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Sid": "SSMListParams",
				"Effect": "Allow",
				"Action": [
					"ssm:DescribeParameters"
				],
				"Resource": "*"
			},
			{
				"Sid": "SSMGetParams",
				"Effect": "Allow",
				"Action": [
					"ssm:GetParameter",
					"ssm:GetParameters"
				],
				"Resource": "arn:aws:ssm:eu-central-1:872907144139:parameter/demo/db/*",
				"Condition": {
					"StringEquals": {
						"aws:PrincipalTag/task": "3"
					}
				}
			}
		]
	}
	```
</details>
<details>
	<summary>Policy for s3 readonly access <b>db-read-s3-script</b></summary>
	```markdown
		# Policy for DbRole

	```json
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Effect": "Allow",
				"Action": [
					"s3:GetObject",
					"s3:DescribeJob",
					"s3:List*"
				],
				"Resource": [
					"arn:aws:s3:::hw-3-yuliia-rul/maria-db-ssm.sh",
					"arn:aws:s3:::hw-3-yuliia-rul/update-env-vars.sh"
				]
			}
		]
	}
	```
</details>
<details>
	<summary>Policy for s3 readonly access <b>APP-read-s3-update-envs</b></summary>
		```markdown
		# Policy for DbRole

	```json
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Effect": "Allow",
				"Action": [
					"s3:GetObject"
				],
				"Resource": "arn:aws:s3:::hw-3-yuliia-rul/update-env-vars.sh"
			}
		]
	}
	```
</details>
<details>
	<summary>Role <b>AppRole</b> for ec2</summary>
	```markdown
		# Role AppRole for EC2

	```json
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Effect": "Allow",
				"Principal": {
					"Service": "ec2.amazonaws.com"
				},
				"Action": "sts:AssumeRole"
			}
		]
	}
	```
</details>


<details>
	<summary>Role <b>DbRole</b> for ec2</summary>
	```markdown
		# Role DbRole for EC2

	```json
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Effect": "Allow",
				"Principal": {
					"Service": "ec2.amazonaws.com"
				},
				"Action": "sts:AssumeRole"
			}
		]
	}
	```
</details>

<details>
	<summary>DB init script</summary>
	```markdown

	```bash
	#!/bin/bash

	# Update package index
	sudo apt-get update

	# Install MariaDB
	sudo apt-get install mariadb-server awscli -y

	# Start MariaDB service
	sudo systemctl start mariadb

	# Enable MariaDB to start on boot
	sudo systemctl enable mariadb

	# Get parameters from AWS Systems Manager Parameter Store
	MYSQL_USER=$(aws ssm get-parameter --name "/demo/db/MYSQL_USER" --query "Parameter.Value" --output text --with-decryption)
	MYSQL_PASS=$(aws ssm get-parameter --name "/demo/db/MYSQL_PASS" --query "Parameter.Value" --output text --with-decryption)

	# Set root password for MariaDB 
	sudo mysqladmin -u root password "${MYSQL_PASS}"

	# Create a new database
	sudo mysql -u root -p"${MYSQL_PASS}" -e "CREATE DATABASE hillelDB;"

	# Create a new user
	sudo mysql -u root -p"${MYSQL_PASS}" -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';"

	# Grant privileges to the new user for the new database
	sudo mysql -u root -p"${MYSQL_PASS}" -e "GRANT ALL PRIVILEGES ON hillelDB.* TO '${MYSQL_USER}'@'localhost';"

	# Flush privileges
	sudo mysql -u root -p"${MYSQL_PASS}" -e "FLUSH PRIVILEGES;"

	# Restart MariaDB service
	sudo systemctl restart mariadb

	echo "MariaDB installation, database creation, and user setup completed."
	```
</details>

<details>
	<summary>Script to update the environment variables <b>update-env-vars.sh</b> for ec2</summary>
	```markdown
		# script update-env-vars.sh

	```bash
	
	#!/bin/bash

	# Get parameters from AWS Systems Manager Parameter Store
	MYSQL_USER=$(aws ssm get-parameter --name "/demo/db/MYSQL_USER" --query "Parameter.Value" --output text --with-decryption)
	MYSQL_PASS=$(aws ssm get-parameter --name "/demo/db/MYSQL_PASS" --query "Parameter.Value" --output text --with-decryption)
	EXT_PORT=$(aws ssm get-parameter --name "/demo/app/ext_port" --query "Parameter.Value" --output text --with-decryption)

	# Update environment variables in /etc/environment
	echo "Updating environment variables in /etc/environment"

	# Backup current /etc/environment
	sudo cp /etc/environment /etc/environment.bak

	# Remove existing variables if they exist
	sudo sed -i '/^MYSQL_USER=/d' /etc/environment
	sudo sed -i '/^MYSQL_PASS=/d' /etc/environment
	sudo sed -i '/^EXT_PORT=/d' /etc/environment

	# Add new variables
	echo "MYSQL_USER=${MYSQL_USER}" | sudo tee -a /etc/environment
	echo "MYSQL_PASS=${MYSQL_PASS}" | sudo tee -a /etc/environment
	echo "EXT_PORT=${EXT_PORT}" | sudo tee -a /etc/environment

	# Source the updated environment file to apply changes immediately
	source /etc/environment

	echo "Environment variables updated successfully."

	# Optional: Restart any services that rely on these environment variables
	# Example: sudo systemctl restart my-app-service

	```
</details>