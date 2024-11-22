import requests
import json
import os

SLURM_URL="http://127.0.0.1:6820"
API_VER="v0.0.37"
USER_NAME=os.getenv("SLURM_USER_NAME")
SLURM_JWT=os.getenv("SLURM_JWT")

response = requests.post(
    f'{SLURM_URL}/slurm/{API_VER}/job/submit',
    headers={
        'X-SLURM-USER-NAME': f'{USER_NAME}',
        'X-SLURM-USER-TOKEN': f'{SLURM_JWT}'
    },
    json={
        'script': 'echo "Hello, world"',
        'job': {
            'qos': 'default',
            'time_limit': 5,
            'environment': {
                'USER': 'u000000'
            }
        }
    })

response.raise_for_status()
print(json.dumps(response.json(), indent=2))
