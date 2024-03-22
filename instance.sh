#!/bin/bash

# Function to tag EC2 instances
tag_ec2_instances() {
    # Get instance IDs
    instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)

    # Loop through instance IDs and tag each one
    for instance_id in $instance_ids; do
        aws ec2 create-tags --resources $instance_id --tags Key=backup,Value=true
        echo "Tagged instance $instance_id with backup=true"
    done
}

# Function to tag EBS volumes
tag_ebs_volumes() {
    # Get volume IDs
    volume_ids=$(aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text)

    # Loop through volume IDs and tag each one
    for volume_id in $volume_ids; do
        aws ec2 create-tags --resources $volume_id --tags Key=backup,Value=true
        echo "Tagged volume $volume_id with backup=true"
    done
}

# Main function
main() {
    echo "Tagging EC2 instances..."
    tag_ec2_instances

    echo "Tagging EBS volumes..."
    tag_ebs_volumes

    echo "Tagging completed successfully."
}

# Execute main function
main
