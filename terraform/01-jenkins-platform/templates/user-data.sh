#!/bin/bash
set -euxo pipefail

# --- Install Jenkins (LTS) on Amazon Linux 2023 ---
dnf install -y java-17-amazon-corretto wget

wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

# --- Configure Jenkins ---
mkdir -p /var/lib/jenkins
chown jenkins:jenkins /var/lib/jenkins

cat > /etc/sysconfig/jenkins <<'CONF'
JENKINS_HOME="/var/lib/jenkins"
JENKINS_PORT="8080"
JENKINS_ARGS="--httpListenAddress=0.0.0.0"
CONF

# Set JENKINS_JAVA_OPTS for timezone and encoding
cat >> /etc/sysconfig/jenkins <<CONF
JENKINS_JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dorg.apache.commons.jelly.tags.fmt.timeZone=UTC"
CONF

# --- Start Jenkins ---
systemctl enable jenkins
systemctl start jenkins

# --- Install AWS CLI v2 ---
curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscli.zip
unzip -qo /tmp/awscli.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscli.zip

echo "Jenkins controller bootstrap complete — ${project_name}"
