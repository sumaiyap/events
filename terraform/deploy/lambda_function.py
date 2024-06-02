import boto3
import os
import time

def lambda_handler(event, context):
    instance_id = os.getenv('EC2_INSTANCE_ID')
    ssm_client = boto3.client('ssm')
    
    commands = [
        'git clone https://github.com/sumaiyap/events.git /home/ubuntu/events',
        'cd /home/ubuntu/events/application/ && docker-compose down --volumes --rmi all',
        'cd /home/ubuntu/events/application/ && docker-compose up -d'
    ]
    
    response = ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={'commands': commands}
    )
    
    command_id = response['Command']['CommandId']
    
    # Wait and retry mechanism
    for _ in range(30):  # Retry for a total of 30 times
        time.sleep(10)  # Wait 10 seconds between retries
        try:
            output = ssm_client.get_command_invocation(
                CommandId=command_id,
                InstanceId=instance_id,
            )
            print(output)
            return output
        except ssm_client.exceptions.InvocationDoesNotExist:
            print("Invocation does not exist yet. Retrying...")

    raise Exception("Command invocation did not complete in time.")
