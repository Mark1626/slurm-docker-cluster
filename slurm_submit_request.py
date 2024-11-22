import requests
import json
import os

SLURM_URL = "http://127.0.0.1:6820"
API_VER = "v0.0.37"
USER_NAME = os.getenv("SLURM_USER_NAME")
SLURM_JWT = os.getenv("SLURM_JWT")
JOB_NAME = os.getenv("JOB_NAME")
TASKS = os.getenv("TASKS")
PARTITION = os.getenv("PARTITION")

response = requests.post(
    f'{SLURM_URL}/slurm/{API_VER}/job/submit',
    headers={
        'X-SLURM-USER-NAME': f'{USER_NAME}',
        'X-SLURM-USER-TOKEN': f'{SLURM_JWT}'
    },
    json={
        'jobs': [
            {
                'name': JOB_NAME,
                'tasks': TASKS,
                'partition': PARTITION,
                'qos': 'default',
                'time_limit': 5,
                'script': 'echo "Hello, world"',
                'environment': {
                    'USER': 'u000000'
                }
            }
        ]
    })

response.raise_for_status()
print(json.dumps(response.json(), indent=2))
