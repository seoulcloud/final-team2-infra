MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
# EKS Node User Data Script with SSM Support
set -o xtrace

# Configure EKS bootstrap
/etc/eks/bootstrap.sh ${cluster_name} \
    --b64-cluster-ca ${cluster_ca} \
    --apiserver-endpoint ${cluster_endpoint}

%{ if enable_ssm_access }
# Configure SSM Agent
echo "Configuring SSM Agent..."

# Install SSM Agent if not present (should be pre-installed on Amazon Linux 2)
if ! systemctl is-active --quiet amazon-ssm-agent; then
    echo "Starting SSM Agent..."
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
else
    echo "SSM Agent is already running"
fi

# Verify SSM Agent status
systemctl status amazon-ssm-agent

# Configure CloudWatch Agent for monitoring (optional)
yum install -y amazon-cloudwatch-agent

# Set up logging for EKS nodes
cat > /etc/rsyslog.d/50-eks.conf << 'EOF'
# EKS Node Logging
:programname, isequal, "kubelet" /var/log/eks/kubelet.log
:programname, isequal, "dockerd" /var/log/eks/docker.log
& stop
EOF

systemctl restart rsyslog

echo "SSM configuration completed"
%{ endif }

# Additional node configuration
echo "EKS node initialization completed"

# Signal completion
/opt/aws/bin/cfn-signal -e $? --stack $${AWS_DEFAULT_REGION} --resource NodeGroup --region $${AWS_DEFAULT_REGION} 

--==MYBOUNDARY==-- 