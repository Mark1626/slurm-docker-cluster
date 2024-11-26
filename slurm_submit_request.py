import requests
import json
import os

SLURM_URL = "http://localhost:6820/"
SCRIPT = os.getenv("SCRIPT", "")
API_VER = "v0.0.37"
USER_NAME = os.getenv("SLURM_USER_NAME")
SLURM_JWT = os.getenv("SLURM_JWT")
JOB_NAME = os.getenv("JOB_NAME", "SLURM_JOB")
TASKS = os.getenv("TASKS", 4)
NODES = os.getenv("NODES", 4)
PARTITION = os.getenv("PARTITION", "normal")

response = requests.post(
    f'{SLURM_URL}/slurm/{API_VER}/job/submit',
    headers={
        'X-SLURM-USER-NAME': f'{USER_NAME}',
        'X-SLURM-USER-TOKEN': f'{SLURM_JWT}'
    },
    json={
        "script": f"#!/bin/bash\n {SCRIPT}",
        'job': {
            'name': JOB_NAME,
            "current_working_directory": "/job/",
            "tasks": TASKS,
            "nodes": NODES
            'environment': {
                "PATH": "/bin:/usr/bin/:/usr/local/bin/",
                "LD_LIBRARY_PATH": "/lib/:/lib64/:/usr/local/lib"
            }
        }
    })

response.raise_for_status()
print(json.dumps(response.json(), indent=2))

