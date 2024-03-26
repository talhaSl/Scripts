import boto3
from botocore.exceptions import WaiterError

def wait_until_instance_stopped(ec2_client, instance_id):
    waiter = ec2_client.get_waiter('instance_stopped')
    try:
        waiter.wait(InstanceIds=[instance_id])
        print("Instance stopped successfully.")
    except WaiterError as e:
        print(f"Error waiting for instance to stop: {e}")

# Define the instance ID
#instance_id = "i-xxxxxxxxxxxxx"
instance_id = event['instanceId']
# Create an EC2 client
ec2_client = boto3.client('ec2')

try:
    # Stop the instance
    ec2_client.stop_instances(InstanceIds=[instance_id])

    # Wait until the instance is stopped
    wait_until_instance_stopped(ec2_client, instance_id)

    # Modify the instance type
    ec2_client.modify_instance_attribute(InstanceId=instance_id, InstanceType={'Value': 't2.medium'})

    print("Instance type modified to t2.medium.")

    # Start the instance
    ec2_client.start_instances(InstanceIds=[instance_id])

    print("Instance started successfully.")

except Exception as e:
    print(f'Error resizing instance: {e}')
