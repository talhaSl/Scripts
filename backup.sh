#!/bin/bash

SOURCE_REGION="us-east-1"
DESTINATION_REGION_BACKUP="us-east-1"
DESTINATION_REGION_SNAPSHOT="us-east-2"

# Get a list of all EC2 instances in the source region
INSTANCE_IDS=$(aws ec2 describe-instances --region $SOURCE_REGION --query 'Reservations[*].Instances[*].InstanceId' --output text)

# Iterate over each instance and create/copy snapshots
for INSTANCE_ID in $INSTANCE_IDS; do
    echo "Processing EC2 instance: $INSTANCE_ID"

    # Get the EC2 instance name
    INSTANCE_NAME=$(aws ec2 describe-instances --region $SOURCE_REGION --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].Tags[?Key==`Name`].Value' --output text)

    # Get the AMI ID associated with the EC2 instance
    AMI_ID=$(aws ec2 describe-instances --region $SOURCE_REGION --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].ImageId' --output text)

    # Get a list of volume IDs attached to the instance
    VOLUME_IDS=$(aws ec2 describe-instances --region $SOURCE_REGION --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId' --output text)

    # Create a timestamp in the format year-month-day
    TIMESTAMP=$(date +"%Y-%m-%d")

    for VOLUME_ID in $VOLUME_IDS; do
        # Create a new snapshot for each volume of the specified EC2 instance in the source region
        NEW_SNAPSHOT_NAME="Snapshot_${INSTANCE_NAME}_${INSTANCE_ID}_${AMI_ID}_Volume_${VOLUME_ID}_${TIMESTAMP}"

        echo "Creating a new snapshot for EC2 instance $INSTANCE_ID ($INSTANCE_NAME), Volume $VOLUME_ID in $SOURCE_REGION..."
        SNAPSHOT_RESULT=$(aws ec2 create-snapshot --region $SOURCE_REGION --volume-id $VOLUME_ID --description "$NEW_SNAPSHOT_NAME")

        # Extract the new snapshot ID from the creation result
        SNAPSHOT_ID=$(echo "$SNAPSHOT_RESULT" | grep -oP '(?<="SnapshotId": ")[^"]+')

        if [ -z "$SNAPSHOT_ID" ]; then
            echo "Error creating snapshot for EC2 instance $INSTANCE_ID, Volume $VOLUME_ID in $SOURCE_REGION"
            continue
        fi

        echo "Snapshot created for EC2 instance $INSTANCE_ID ($INSTANCE_NAME), Volume $VOLUME_ID in $SOURCE_REGION with ID: $SNAPSHOT_ID"

        # Copy the newly created snapshot to the destination region for snapshots
        NEW_COPY_SNAPSHOT_NAME="Created_by_CreateImage(${INSTANCE_NAME})(${INSTANCE_ID})(${AMI_ID})_${TIMESTAMP}"
        echo "Copying snapshot $SNAPSHOT_ID from $SOURCE_REGION to $DESTINATION_REGION_SNAPSHOT..."
        COPY_RESULT=$(aws ec2 copy-snapshot --region $DESTINATION_REGION_SNAPSHOT --source-region $SOURCE_REGION --source-snapshot-id $SNAPSHOT_ID --description "$NEW_COPY_SNAPSHOT_NAME")

        # Extract the new snapshot ID from the copy result
        NEW_SNAPSHOT_ID=$(echo "$COPY_RESULT" | grep -oP '(?<="SnapshotId": ")[^"]+')

        if [ -z "$NEW_SNAPSHOT_ID" ]; then
            echo "Error during snapshot copy to $DESTINATION_REGION_SNAPSHOT for snapshot $SNAPSHOT_ID"
            continue
        fi

        echo "Snapshot $SNAPSHOT_ID copied to $DESTINATION_REGION_SNAPSHOT with new ID: $NEW_SNAPSHOT_ID and name: $NEW_COPY_SNAPSHOT_NAME"

        # Create an AWS Backup plan for each EC2 instance in the source region for backups
        BACKUP_PLAN_NAME="BackupPlan_${INSTANCE_NAME}_${INSTANCE_ID}_${TIMESTAMP}"

        echo "Creating AWS Backup plan for EC2 instance $INSTANCE_ID ($INSTANCE_NAME) in $DESTINATION_REGION_BACKUP..."
        aws backup create-backup-plan --cli-input-json '{"BackupPlan":{"BackupPlanName":"'$BACKUP_PLAN_NAME'","Rules":[{"RuleName":"DailyBackupRule","TargetBackupVault":"'$DESTINATION_REGION_BACKUP'","ScheduleExpression":"cron(0 0 * * ? *)","StartWindowMinutes":60,"Lifecycle":{"DeleteAfterDays":7}}]}}'

        echo "AWS Backup plan created for EC2 instance $INSTANCE_ID ($INSTANCE_NAME) in $DESTINATION_REGION_BACKUP"
    done
done

echo "Snapshot and AWS Backup plan creation process completed for all EC2 instances."
