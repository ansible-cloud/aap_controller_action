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
stdout_callback=community.general.yaml

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
      register: job_output

    - name: Wait for job
      awx.awx.job_wait:
        job_id: "{{ job_output.id }}"
        timeout: 1800
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        controller_username: "$CONTROLLER_USERNAME"
        controller_password: "$CONTROLLER_PASSWORD"
        controller_host: "$CONTROLLER_HOST"

    - name: retrieve job info
      uri:
        url: https://$CONTROLLER_HOST/api/v2/jobs/{{ job_output.id }}/stdout/?format=json
        method: GET
        user: "$CONTROLLER_USERNAME"
        password: "$CONTROLLER_PASSWORD"
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        force_basic_auth: yes
      register: playbook_output

    - debug:
        var: playbook_output.json.content
EOF

echo "AAP Github Action - Executing Automation Job on Automation controller"

/usr/local/bin/ansible-playbook playbook.yml

if [ $? -eq 0 ]; then
    echo "Ansible Job has executed successfully"
else
    echo "Ansible Job has failed"
    exit 1
fi

echo "END OF AAP - Automation controller Github Action"
