#!/bin/sh

for ID in $(aws autoscaling describe-auto-scaling-instances --region us-west-2 --query AutoScalingInstances[].InstanceId --output text);
do
    aws ec2 describe-instances --instance-ids $ID --region us-west-2 --query Reservations[].Instances[].PublicDnsName --output text
done
