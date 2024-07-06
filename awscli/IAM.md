
## intro
### Перелік використаних змінних
- `/demo/app/ext_port` 
- `/demo/db/MYSQL_PASS`
- `/demo/db/MYSQL_USER`
- `/demo/db/priv_ip`

tag 'task' value 3

- aws iam tag-instance-profile --instance-profile-name s3-ro-test-role --tags '[{"Key": "task", "Value
": "3"}]'
- aws iam list-instance-profile-tags --instance-profile-name "s3-ro-test-role"
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
						"aws:PrincipalTag/Project": "demo-ssm"
					}
				}
			}
		]
	}
	```
</details>
<details>
	<summary>Policy for s3 readonly access <b>S3-RO</b></summary>
	```markdown
		# Policy

	```json
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Sid": "SSMListParams",
				"Effect": "Allow",
				"Action": [
					"s3:DescribeJob",
					"s3:Get*",
					"s3:List*"
				],
				"Resource": "*"
			}
		]
	}
	```
</details>
<details>
	<summary>Role <b>s3-ro-test-role</b> for ec2</summary>
	```markdown
		# Role s3-ro-test-role for EC2

	```
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

