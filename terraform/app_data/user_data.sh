#!/bin/bash
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
curl -L "https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo apt-get install -y awscli
sudo useradd --no-create-home --shell /bin/false node_exporter
mkdir -P /home/ubuntu/nginx-log

# Step 3: Download Node Exporter
VERSION="1.5.0"
wget https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz

# Step 4: Extract the Node Exporter Tarball
tar -xvf node_exporter-$VERSION.linux-amd64.tar.gz

# Move the Node Exporter binary to the appropriate directory
sudo mv node_exporter-$VERSION.linux-amd64/node_exporter /usr/local/bin/

# Step 5: Set Up Directories and Permissions
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Step 6: Create a Systemd Service File
sudo bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF'

# Step 7: Reload Systemd and Start Node Exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
