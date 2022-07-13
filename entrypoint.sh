#! /usr/bin/bash

echo "AAP - Automation controller Github Action"

echo "CONTROLLER_HOST is $CONTROLLER_HOST"

if [ -z "$CONTROLLER_HOST" ]; then
  echo "Automation controller host is not set. Exiting."
  exit 1
fi

if [ -z "$CONTROLLER_USERNAME" ]; then
  echo "Automation controller username is not set. Exiting."
  exit 1
fi

if [ -z "$CONTROLLER_PASSWORD" ]; then
  echo "Automation controller password is not set. Exiting."
  exit 1
fi

echo "JOB_TEMPLATE being executed $JOB_TEMPLATE"


tee ansible.cfg << EOF
[defaults]
COLLECTIONS_PATHS = /root/.ansible/collections

EOF


tee playbook.yml << EOF
---
- name: execute autmation job
  hosts: localhost
  gather_facts: no

  tasks:

    - name: Launch a job template with extra_vars on remote controller instance
      awx.awx.job_launch:
        job_template: "$JOB_TEMPLATE"
        extra_vars:
          your_region: "us-east-1"
          var2: "My Second Variable"
          var3: "My Third Variable"
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        controller_username: "$CONTROLLER_USERNAME"
        controller_password: "$CONTROLLER_PASSWORD"
        controller_host: "$CONTROLLER_HOST"
EOF

ansible-galaxy collection list
ls /root/.ansible/collections/ansible_collections

/usr/local/bin/ansible-playbook playbook.yml

echo "END OF AAP - Automation controller Github Action"
