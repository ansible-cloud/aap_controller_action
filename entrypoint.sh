#! /usr/bin/bash
# PY_COLORS: '1'
# ANSIBLE_FORCE_COLOR: '1'

export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1

echo "AAP - Automation controller Github Action"

# Required inputs
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

echo "CONTROLLER_HOST is $CONTROLLER_HOST"
echo "JOB_TEMPLATE being executed $JOB_TEMPLATE"
echo "EXTRA_VARS is set to $EXTRA_VARS"
echo "CONTROLLER_VERIFY_SSL is set to $CONTROLLER_VERIFY_SSL"
echo "CONTROLLER_PROJECT is set to $CONTROLLER_PROJECT"
echo "----------------"
echo "GITHUB_BASE_REF is $GITHUB_BASE_REF"
echo "GITHUB_HEAD_REF is $GITHUB_HEAD_REF"
echo "GITHUB_REF_NAME is $GITHUB_REF_NAME"
echo "GITHUB_EVENT_NAME is $GITHUB_EVENT_NAME"
echo "GITHUB_JOB is $GITHUB_JOB"
echo "GITHUB_REF is $GITHUB_REF"
echo "GITHUB_REPOSITORY is $GITHUB_REPOSITORY"
echo "pull_request_event is $pull_request_event"
echo "---------------"
echo "WORKFLOW_TEMPLATE is $WORKFLOW_TEMPLATE"
echo "---------------"

# Build SCM fields
scm_url="https://github.com/$GITHUB_REPOSITORY"
echo "scm_url is $scm_url"

scm_branch="pull/$pull_request_event/head"
echo "scm_branch is $scm_branch"

# Write ansible.cfg
tee ansible.cfg << 'EOF'
[defaults]
COLLECTIONS_PATHS = /root/.ansible/collections
stdout_callback = default
callback_result_format = yaml
callbacks_enabled = ansible.posix.profile_tasks
EOF


############################################
# PLAYBOOK WITH CORRECT VARIABLE INJECTION
############################################
tee playbook.yml << EOF
---
- name: execute automation job
  hosts: localhost
  gather_facts: no

  vars:
    controller_verify: $CONTROLLER_VERIFY_SSL
    controller_host: "$CONTROLLER_HOST"
    controller_user: "$CONTROLLER_USERNAME"
    controller_pass: "$CONTROLLER_PASSWORD"

  tasks:

    - name: grab github action input
      set_fact:
        job_template_var: "$JOB_TEMPLATE"
        workflow_template_var: "$WORKFLOW_TEMPLATE"
        extra_vars: $EXTRA_VARS
        project_var: "$CONTROLLER_PROJECT"
        scm_branch: "$scm_branch"
        scm_url: "$scm_url"

    - name: print out extra_vars
      debug:
        var: extra_vars

    - name: print out workflow_template_var length
      debug:
        msg: "workflow_template_var | length is {{ workflow_template_var | length }}"

    ########################################################################
    # PROJECT UPDATE + JOB TEMPLATE UPDATE
    ########################################################################
    - name: project update and sync
      when: workflow_template_var | length == 0
      block:

        - name: retrieve project + job template info
          set_fact:
            project_info: "{{ query('awx.awx.controller_api', 'projects', verify_ssl=controller_verify, query_params={'name': project_var}) }}"
            template_info: "{{ query('awx.awx.controller_api', 'job_templates', verify_ssl=controller_verify, query_params={'name': job_template_var}) }}"
            scm_refspec: "refs/pull/*:refs/remotes/origin/pull/*"

        - name: print out existing project settings
          debug:
            msg:
              - description: "{{ project_info[0].description }}"
              - organization: "{{ project_info[0].organization }}"
              - default_environment: "{{ project_info[0].default_environment }}"
              - scm_type: "{{ project_info[0].scm_type }}"
              - scm_url: "{{ project_info[0].scm_url }}"
              - scm_branch: "{{ project_info[0].scm_branch }}"
              - scm_refspec: "{{ project_info[0].scm_refspec }}"
              - credential: "{{ project_info[0].credential }}"
              - scm_clean: "{{ project_info[0].scm_clean }}"
              - scm_delete_on_update: "{{ project_info[0].scm_delete_on_update }}"
              - scm_track_submodules: "{{ project_info[0].scm_track_submodules }}"
              - scm_update_on_launch: "{{ project_info[0].scm_update_on_launch }}"
              - allow_override: "{{ project_info[0].allow_override }}"

        - name: print template settings
          debug:
            msg:
              - allow_simultaneous: "{{ template_info[0].allow_simultaneous }}"
              - ask_credential_on_launch: "{{ template_info[0].ask_credential_on_launch }}"
              - ask_diff_mode_on_launch: "{{ template_info[0].ask_diff_mode_on_launch }}"
              - ask_inventory_on_launch: "{{ template_info[0].ask_inventory_on_launch }}"
              - ask_job_type_on_launch: "{{ template_info[0].ask_job_type_on_launch }}"
              - ask_limit_on_launch: "{{ template_info[0].ask_limit_on_launch }}"
              - ask_scm_branch_on_launch: "{{ template_info[0].ask_scm_branch_on_launch }}"
              - ask_skip_tags_on_launch: "{{ template_info[0].ask_skip_tags_on_launch }}"
              - ask_tags_on_launch: "{{ template_info[0].ask_tags_on_launch }}"
              - ask_variables_on_launch: "{{ template_info[0].ask_variables_on_launch }}"
              - ask_verbosity_on_launch: "{{ template_info[0].ask_verbosity_on_launch }}"
              - become_enabled: "{{ template_info[0].become_enabled }}"
              - description: "{{ template_info[0].description }}"
              - diff_mode: "{{ template_info[0].diff_mode }}"
              - execution_environment: "{{ template_info[0].execution_environment }}"
              - inventory: "{{ template_info[0].inventory }}"
              - job_type: "{{ template_info[0].job_type }}"
              - playbook: "{{ template_info[0].playbook }}"
              - scm_branch: "{{ template_info[0].scm_branch }}"
              - webhook_service: "{{ template_info[0].webhook_service }}"
              - webhook_credential: "{{ template_info[0].webhook_credential }}"

        - name: extract credentials
          set_fact:
            credentials: >-
              {{ template_info[0].summary_fields.credentials | map(attribute='name') | list }}

        - name: update project
          awx.awx.project:
            name: "{{ project_var }}"
            state: present
            description: "{{ project_info[0].description }}"
            organization: "{{ project_info[0].organization }}"
            default_environment: "{{ project_info[0].default_environment }}"
            scm_type: "{{ project_info[0].scm_type }}"
            scm_url: "{{ scm_url }}"
            scm_branch: "{{ project_info[0].scm_branch }}"
            scm_refspec: "{{ scm_refspec }}"
            scm_clean: "{{ project_info[0].scm_clean }}"
            scm_delete_on_update: "{{ project_info[0].scm_delete_on_update }}"
            scm_track_submodules: "{{ project_info[0].scm_track_submodules }}"
            scm_update_on_launch: true
            allow_override: true
            validate_certs: "{{ controller_verify }}"

        - name: update job template (enable ask_scm_branch_on_launch)
          awx.awx.job_template:
            name: "{{ template_info[0].name }}"
            project: "{{ template_info[0].project }}"
            ask_scm_branch_on_launch: true
            allow_simultaneous: "{{ template_info[0].allow_simultaneous }}"
            ask_inventory_on_launch: "{{ template_info[0].ask_inventory_on_launch }}"
            ask_tags_on_launch: "{{ template_info[0].ask_tags_on_launch }}"
            ask_skip_tags_on_launch: "{{ template_info[0].ask_skip_tags_on_launch }}"
            ask_variables_on_launch: "{{ template_info[0].ask_variables_on_launch }}"
            credentials: "{{ credentials | default(omit) }}"
            inventory: "{{ template_info[0].inventory }}"
            playbook: "{{ template_info[0].playbook }}"
            validate_certs: "{{ controller_verify }}"

    ########################################################################
    # JOB LAUNCH
    ########################################################################
    - name: launch a job and wait
      when: job_template_var | length > 0
      block:

        - name: Launch template
          awx.awx.job_launch:
            job_template: "{{ job_template_var }}"
            extra_vars: "{{ extra_vars }}"
            validate_certs: "{{ controller_verify }}"
            scm_branch: "{{ scm_branch }}"
          register: job_output

        - name: wait for job
          awx.awx.job_wait:
            job_id: "{{ job_output.id }}"
            timeout: 3600
            validate_certs: "{{ controller_verify }}"

        - name: retrieve job stdout
          uri:
            url: "https://{{ controller_host }}/api/v2/jobs/{{ job_output.id }}/stdout/?format=json"
            method: GET
            user: "{{ controller_user }}"
            password: "{{ controller_pass }}"
            validate_certs: "{{ controller_verify }}"
            force_basic_auth: yes
          register: playbook_output

        - name: show stdout
          debug:
            var: playbook_output.json.content

        - name: save stdout to file
          copy:
            content: "{{ playbook_output.json.content }}"
            dest: job_output.txt

    ########################################################################
    # WORKFLOW LAUNCH
    ########################################################################
    - name: launch workflow and wait
      when: workflow_template_var | length > 0
      block:

        - name: Launch workflow
          awx.awx.workflow_launch:
            workflow_template: "{{ workflow_template_var }}"
            extra_vars: "{{ extra_vars }}"
            validate_certs: "{{ controller_verify }}"
            scm_branch: "{{ scm_branch }}"
          register: workflow_output

        - debug:
            var: workflow_output

        - name: wait
          awx.awx.job_wait:
            job_id: "{{ workflow_output.id }}"
            job_type: workflow_jobs
            timeout: 3600
            validate_certs: "{{ controller_verify }}"
EOF


echo "AAP Github Action - Executing Automation Job on Automation Controller"

ansible-playbook playbook.yml
status=$?

if [ $status -eq 0 ]; then
    echo "Ansible Github Action Job executed successfully"
else
    echo "Ansible Github Action Job failed"
    exit 1
fi

echo "END OF AAP - Automation Controller Github Action"
