#!/bin/bash
sudo su
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
sudo apt-get update -y
sudo apt install openjdk-11-jdk -y
sudo rm /etc/apt/sources.list.d/jenkins.list
sudo apt upgrade -y
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install jenkins -y
sudo apt-get install -y awscli
sudo usermod -aG docker jenkins
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y

sudo useradd --no-create-home --shell /bin/false prometheus
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.40.1/prometheus-2.40.1.linux-amd64.tar.gz
tar -xvf prometheus-2.40.1.linux-amd64.tar.gz
rm -rf prometheus-2.40.1.linux-amd64.tar.gz
sudo mv prometheus-2.40.1.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-2.40.1.linux-amd64/promtool /usr/local/bin/
sudo mv prometheus-2.40.1.linux-amd64/consoles /etc/prometheus/
sudo mv prometheus-2.40.1.linux-amd64/console_libraries /etc/prometheus/
sudo mkdir /etc/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo mv prometheus-2.40.1.linux-amd64/prometheus.yml /etc/prometheus/
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
sudo bash -c 'cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]  
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
--config.file=/etc/prometheus/prometheus.yml \\
--storage.tsdb.path=/var/lib/prometheus/ \\
--web.console.templates=/etc/prometheus/consoles \\
--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF'


sudo bash -c 'cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter_aws'

    ec2_sd_configs:
      - region: us-east-1
        port: 9100
        filters: 
          - name: tag:Name
            values:
              - Jenkins
              - web-app

    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: Name
EOF'

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

sudo useradd --no-create-home --shell /bin/false node_exporter

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

docker run -d --name=grafana -p 3000:3000 grafana/grafana