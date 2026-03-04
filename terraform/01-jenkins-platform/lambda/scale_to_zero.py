import boto3, os, json

ec2 = boto3.client('ec2', region_name=os.environ.get('TARGET_REGION', os.environ.get('AWS_REGION')))
INSTANCE_ID = os.environ['INSTANCE_ID']

def handler(event, context):
    action = event.get('action', 'stop')
    if action == 'start':
        ec2.start_instances(InstanceIds=[INSTANCE_ID])
        print(f'Started {INSTANCE_ID}')
    elif action == 'stop':
        ec2.stop_instances(InstanceIds=[INSTANCE_ID])
        print(f'Stopped {INSTANCE_ID}')
    return {'statusCode': 200, 'body': json.dumps(f'{action} {INSTANCE_ID}')}
