#!/bin/bash

# Prompt for MySQL root password
read -sp "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
echo

# Prompt for remote user name
read -p "Enter remote user name: " REMOTE_USER

# Prompt for remote user password
read -sp "Enter remote user password: " REMOTE_USER_PASSWORD
echo

# Define the remote host
REMOTE_HOST="%" # % allows access from any IP address, or specify an IP/range for restricted access

# Define the MySQL configuration file
MYSQL_CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Check if the MySQL configuration file exists
if [ ! -f "$MYSQL_CONFIG_FILE" ]; then
  echo "MySQL configuration file not found at $MYSQL_CONFIG_FILE"
  exit 1
fi

# Backup the current MySQL configuration file
echo "Backing up the MySQL configuration file..."
sudo cp "$MYSQL_CONFIG_FILE" "${MYSQL_CONFIG_FILE}.bak"

# Change the bind-address to 0.0.0.0 to allow remote access
echo "Setting bind-address to 0.0.0.0..."
sudo sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' "$MYSQL_CONFIG_FILE"

# Restart the MySQL service to apply changes
echo "Restarting MySQL service..."
sudo systemctl restart mysql

# Check if MySQL service restarted successfully
if systemctl is-active --quiet mysql; then
  echo "MySQL service restarted successfully."
else
  echo "Failed to restart MySQL service."
  exit 1
fi

# Create a remote user and grant all privileges on all databases
echo "Creating remote user and granting privileges on all databases..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "
CREATE USER IF NOT EXISTS '$REMOTE_USER'@'$REMOTE_HOST' IDENTIFIED BY '$REMOTE_USER_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$REMOTE_USER'@'$REMOTE_HOST' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

# Check if the user was created successfully
if [ $? -eq 0 ]; then
  echo "Remote user '$REMOTE_USER' created successfully and granted access to all databases."
else
  echo "Failed to create remote user or grant privileges."
  exit 1
fi

echo "MySQL remote access and user setup complete."
