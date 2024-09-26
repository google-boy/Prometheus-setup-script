#!/bin/bash

# Prometheus Installation Script
# This script installs Prometheus on a Linux system,
# sets it up as a systemd service, and ensures it's running.

# Function to check the last command status and exit on failure
check_status() {
  if [ $? -ne 0 ]; then
    echo "Error occurred in the previous command. Exiting."
    exit 1
  fi
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# Detect the operating system
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "Unsupported operating system."
  exit 1
fi

# Variables
VERSION="2.54.1"  # Change this to the latest version if needed
USER="prometheus"
GROUP="prometheus"
DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz"
DIR="/etc/prometheus"
VAR_DIR="/var/lib/prometheus"

# Update package list and install necessary packages
case $OS in
  ubuntu|debian)
    echo "Updating package list..."
    apt-get update
    check_status

    echo "Installing wget and tar..."
    apt-get install -y wget tar
    check_status
    ;;
  centos|fedora|rhel)
    echo "Installing wget and tar..."
    yum install -y wget tar
    check_status
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

# Create system group and user for prometheus
echo "Creating system group and user for prometheus..."
if ! getent group $GROUP > /dev/null 2>&1; then
  groupadd --system $GROUP
  check_status
else
  echo "Group $GROUP already exists."
fi

if ! id -u $USER > /dev/null 2>&1; then
  useradd --system -g $GROUP --no-create-home --shell /sbin/nologin $USER
  check_status
else
  echo "User $USER already exists."
fi

# Download and extract Prometheus
echo "Downloading Prometheus version $VERSION..."
wget $DOWNLOAD_URL
check_status

echo "Extracting Prometheus..."
tar -xvf prometheus-$VERSION.linux-amd64.tar.gz
check_status

# Creating Prometheus Configuration directory

mkdir -p $DIR
mkdir -p $VAR_DIR

# Move the binaries to /usr/local/bin
echo "Moving Prometheus binaries to /usr/local/bin..."
cp prometheus-$VERSION.linux-amd64/prometheus /usr/local/bin/
cp prometheus-$VERSION.linux-amd64/promtool /usr/local/bin/
cp -r prometheus-$VERSION.linux-amd64/consoles $DIR/
cp -r prometheus-$VERSION.linux-amd64/console_libraries $DIR/
cp prometheus-$VERSION.linux-amd64/prometheus.yml $DIR/

check_status

# Set permissions
echo "Setting permissions for Prometheus binaries and configurations..."
chown $USER:$GROUP /usr/local/bin/prometheus $DIR $VAR_DIR
# chown $USER:$GROUP $DIR
# chown $USER:$GROUP $VAR_DIR 
check_status

# Clean up downloaded files
echo "Cleaning up..."
rm -rf prometheus-$VERSION.linux-amd64.tar.gz* prometheus-$VERSION.linux-amd64

# Create systemd service file
echo "Creating systemd service file for Prometheus..."
cat <<EOF | tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Service
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$GROUP
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path ${VAR_DIR}/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_lbraries

[Install]
WantedBy=default.target
EOF
check_status



# Reload systemd daemon and start Prometheus service
echo "Reloading systemd daemon..."
systemctl daemon-reload
check_status

echo "Enabling Prometheus service..."
systemctl enable prometheus
check_status

echo "Starting Prometheus service..."
systemctl start prometheus
check_status

# Check Prometheus service status
# echo "Prometheus service status..."
# systemctl status prometheus

echo "Prometheus installation completed successfully."