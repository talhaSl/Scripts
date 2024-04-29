#!/bin/bash

# Function to delete specific snapshot
delete_specific_snapshot() {
    # Initialize the AWS CLI
    aws ec2 delete-snapshot --snapshot-id "$1"
    echo "Deleted snapshot with ID: $1"
}

# Specify the list of snapshot IDs to delete
snapshot_ids_to_delete=("snap-0e7cca37e629d0fa4" "snap-0f2d78716d932ee91")

# Iterate over each snapshot ID and delete it
for snapshot_id in "${snapshot_ids_to_delete[@]}"
do
    delete_specific_snapshot "$snapshot_id"
done
