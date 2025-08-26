MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
# EKS Node User Data Script - Simplified for Managed Node Groups
set -o xtrace

%{ if enable_ssm_access }
# Configure SSM Agent for EKS nodes
echo "Configuring SSM Agent for EKS nodes..."

# Ensure SSM Agent is enabled and running
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Verify SSM Agent status
if systemctl is-active --quiet amazon-ssm-agent; then
    echo "SSM Agent is running successfully"
else
    echo "Warning: SSM Agent failed to start"
fi
%{ endif }

# EKS Managed Node Groups handle bootstrap automatically
# No manual bootstrap script needed

echo "EKS node initialization completed at $(date)"

--==MYBOUNDARY==-- 