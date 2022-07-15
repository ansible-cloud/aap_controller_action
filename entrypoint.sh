#! /usr/bin/bash

echo "AAP - Automation controller Github Action"

echo "CONTROLLER_HOST is $CONTROLLER_HOST"
echo "JOB_TEMPLATE being executed $JOB_TEMPLATE"
echo "EXTRA_VARS is set to $EXTRA_VARS"
echo "CONTROLLER_VERIFY_SSL is set to $CONTROLLER_VERIFY_SSL"

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



tee ansible.cfg << EOF
[defaults]
COLLECTIONS_PATHS = /root/.ansible/collections
stdout_callback=community.general.yaml
callbacks_enabled=ansible.posix.profile_tasks

EOF


tee playbook.yml << EOF
---
- name: execute autmation job
  hosts: localhost
  gather_facts: no

  tasks:

    - name: grab github action input
      set_fact:
        job_template_var: "$JOB_TEMPLATE"
        workflow_template_var: "$WORKFLOW_TEMPLATE"
        project_var: "$PROJECT"
        extra_vars: "$EXTRA_VARS"

    - name: print out extra_vars
      debug:
        msg:
          - "extra vars are {{ extra_vars }}"
          - "extra vars are {{ extra_vars }}"

    - name: Launch a job template with extra_vars on remote controller instance
      when: job_template_var|length > 0
      awx.awx.job_launch:
        job_template: "{{ job_template_var }}"
        extra_vars: "$EXTRA_VARS"
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        controller_username: "$CONTROLLER_USERNAME"
        controller_password: "$CONTROLLER_PASSWORD"
        controller_host: "$CONTROLLER_HOST"
      register: job_output

    - name: Wait for job
      when: job_template_var|length > 0 or workflow_template_var|length > 0
      awx.awx.job_wait:
        job_id: "{{ job_output.id }}"
        timeout: 3600
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        controller_username: "$CONTROLLER_USERNAME"
        controller_password: "$CONTROLLER_PASSWORD"
        controller_host: "$CONTROLLER_HOST"

    - name: retrieve job info
      when: job_template_var|length > 0 or workflow_template_var|length > 0
      uri:
        url: https://$CONTROLLER_HOST/api/v2/jobs/{{ job_output.id }}/stdout/?format=json
        method: GET
        user: "$CONTROLLER_USERNAME"
        password: "$CONTROLLER_PASSWORD"
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        force_basic_auth: yes
      register: playbook_output

    - name: display Automation controller job output
      when: job_template_var|length > 0 or workflow_template_var|length > 0
      debug:
        var: playbook_output.json.content
EOF

echo "AAP Github Action - Executing Automation Job on Automation controller"

/usr/local/bin/ansible-playbook playbook.yml

if [ $? -eq 0 ]; then
    echo "Ansible Github Action Job has executed successfully"
else
    echo "Ansible Github Action Job has failed"
    exit 1
fi

echo "END OF AAP - Automation controller Github Action"
