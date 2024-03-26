import boto3

def lambda_handler(event, context):
    # Create EC2 client
    ec2 = boto3.client('ec2')

    # Tag EC2 instances
    print("Tagging EC2 instances...")
    response = ec2.describe_instances()
    instance_ids = [instance['InstanceId'] for reservation in response['Reservations'] for instance in reservation['Instances']]
    for instance_id in instance_ids:
        ec2.create_tags(Resources=[instance_id], Tags=[{'Key': 'Retention', 'Value': '14-days'}])
        print(f"Tagged instance {instance_id} with Retention=14-days")

    # Tag EBS volumes
    print("Tagging EBS volumes...")
    response = ec2.describe_volumes()
    volume_ids = [volume['VolumeId'] for volume in response['Volumes']]
    for volume_id in volume_ids:
        ec2.create_tags(Resources=[volume_id], Tags=[{'Key': 'Retention', 'Value': '14-days'}])
        print(f"Tagged volume {volume_id} with backup=true")

    print("Tagging completed successfully.")

# Make sure to grant the necessary IAM permissions to the Lambda function for EC2 operations.
