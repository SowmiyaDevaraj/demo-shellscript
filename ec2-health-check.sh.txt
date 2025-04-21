#!/bin/bash

# Variables
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION="${AVAILABILITY_ZONE::-1}"  # Remove last character to get region
SNS_TOPIC_ARN="arn:aws:sns:${REGION}:123456789012:ec2-health-alerts"  # Replace with your SNS ARN

# Check instance status
INSTANCE_STATUS=$(aws ec2 describe-instance-status \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'InstanceStatuses[0].InstanceStatus.Status' \
  --output text)

# Log time
echo "[$(date)] Instance $INSTANCE_ID status: $INSTANCE_STATUS"

# If status is not ok, attempt recovery and notify
if [[ "$INSTANCE_STATUS" != "ok" ]]; then
  aws ec2 reboot-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
  aws sns publish \
    --region "$REGION" \
    --topic-arn "$SNS_TOPIC_ARN" \
    --subject "EC2 Instance Health Issue" \
    --message "EC2 instance $INSTANCE_ID is in $INSTANCE_STATUS state. Reboot triggered from health check script."
fi


#For the Allianz insurance project, I automated EC2 instance health checks by creating a shell script that monitors instance health, reboots impaired instances, and triggers SNS alerts. The script is stored in S3, and using AWS Systems Manager (SSM), it is fetched and executed on all EC2 instances.

#I scheduled the script to run every 30 minutes via EventBridge, eliminating the need for a dedicated monitoring server. This approach is cost-efficient, easily scalable, and fully automated, ensuring the EC2 instances are proactively monitored and issues are addressed without manual intervention.
