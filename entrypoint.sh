#! /usr/bin/bash
# PY_COLORS: '1'
# ANSIBLE_FORCE_COLOR: '1'

export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1

echo "AAP - Automation controller Github Action"

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

# scm_url e.g. https://github.com/ansible-cloud/aap_controller_action
# scm_branch e.g. pull/1/head (for PR #1)
# scm_refspec e.g. refs/pull/1/head:refs/remotes/origin/pull/1/head

scm_url="https://github.com/$GITHUB_REPOSITORY"
echo "scm_url is $scm_url"

scm_branch="pull/$pull_request_event/head"
echo "scm_branch is $scm_branch"

# scm_refspec="refs/pull/*:refs/remotes/origin/pull/*"
# echo "scm_refspec is $scm_refspec"



tee ansible.cfg << EOF
[defaults]
COLLECTIONS_PATHS = /root/.ansible/collections
stdout_callback=community.general.yaml
callbacks_enabled=ansible.posix.profile_tasks

EOF


tee playbook.yml << EOF
---
- name: execute automation job
  hosts: localhost
  gather_facts: no

  tasks:

    - name: grab github action input
      set_fact:
        job_template_var: "$JOB_TEMPLATE"
        workflow_template_var: "$WORKFLOW_TEMPLATE"
        extra_vars: "$EXTRA_VARS"
        project_var: "$CONTROLLER_PROJECT"

    - name: print out extra_vars
      debug:
        msg:
          - "extra vars are {{ extra_vars }}"

    - name: print out workflow_template_var length
      debug:
        msg:
          - "workflow_template_var | length is {{ workflow_template_var | length }}"

    - name: project update and sync
      when: workflow_template_var|length == 0
      block:
        - name: retrieve info on existing specified project in Automation controller
          set_fact:
            project_info: "{{ query('awx.awx.controller_api', 'projects', verify_ssl=$CONTROLLER_VERIFY_SSL, query_params={ 'name': '$CONTROLLER_PROJECT' }) }}"
            template_info: "{{ query('awx.awx.controller_api', 'job_templates', verify_ssl=$CONTROLLER_VERIFY_SSL, query_params={ 'name': '$JOB_TEMPLATE' }) }}"
            scm_url: "$scm_url"
            scm_branch: "$scm_branch"
            scm_refspec: "refs/pull/*:refs/remotes/origin/pull/*"

        - name: print out existing project settings to terminal
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

        - name: print out existing job template settings to terminal
          debug:
            msg:
              - allow_simultaneous: "{{ template_info[0].allow_simultaneous }}"
              - ask_credential_on_launch: "{{ template_info[0].ask_credential_on_launch }}"
              - ask_diff_mode_on_launch: "{{ template_info[0].ask_diff_mode_on_launch }}"
              - ask_inventory_on_launch: "{{ template_info[0].ask_diff_mode_on_launch }}"
              - ask_job_type_on_launch: "{{ template_info[0].ask_job_type_on_launch }}"
              - ask_limit_on_launch: "{{ template_info[0].ask_limit_on_launch }}"
              - ask_scm_branch_on_launch: "{{ template_info[0].ask_scm_branch_on_launch }}"
              - ask_skip_tags_on_launch: "{{ template_info[0].ask_skip_tags_on_launch }}"
              - ask_tags_on_launch: "{{ template_info[0].ask_tags_on_launch }}"
              - ask_variables_on_launch: "{{ template_info[0].ask_variables_on_launch }}"
              - ask_verbosity_on_launch: "{{ template_info[0].ask_verbosity_on_launch }}"
              - become_enabled: "{{ template_info[0].become_enabled }}"
              - credentials: "{{ credentials | default(omit, true) }}"
              - description: "{{ template_info[0].description }}"
              - diff_mode: "{{ template_info[0].diff_mode }}"
              - execution_environment: "{{ template_info[0].execution_environment }}"
              - extra_vars: "{% if not template_info[0].extra_vars | from_yaml %}{}{% else %}blah{% endif %}"
              - force_handlers: "{{ template_info[0].force_handlers }}"
              - forks: "{{ template_info[0].forks }}"
              - host_config_key: "{{ template_info[0].host_config_key }}"
              - inventory: "{{ template_info[0].inventory }}"
              - job_slice_count: "{{ template_info[0].job_slice_count }}"
              - job_tags: "{{ template_info[0].job_tags }}"
              - job_type: "{{ template_info[0].job_type }}"
              - limit: "{{ template_info[0].limit }}"
              - name: "{{ template_info[0].name }}"
              - organization: "{{ template_info[0].organization }}"
              - playbook: "{{ template_info[0].playbook }}"
              - project: "{{ template_info[0].project }}"
              - scm_branch: "{{ template_info[0].scm_branch }}"
              - skip_tags: "{{ template_info[0].skip_tags }}"
              - start_at_task: "{{ template_info[0].start_at_task }}"
              - survey_enabled: "{{ template_info[0].survey_enabled }}"
              - timeout: "{{ template_info[0].timeout }}"
              - use_fact_cache: "{{ template_info[0].use_fact_cache }}"
              - verbosity: "{{ template_info[0].verbosity }}"
              - wobhook_credential: "{{ template_info[0].webhook_credential | default(omit, true) }}"
              - webhook_service: "{{ template_info[0].webhook_service }}"

        - name: figure out creds for JT
          set_fact:
            credentials: "{% if template_info[0].summary_fields['credentials'] | length>0 %}{% for cred in template_info[0].summary_fields['credentials'] %}{{ cred.name }}{% if loop.length > 1 %},{% endif %}{% endfor %}{% endif %}"

        - name: figure out creds for JT
          set_fact:
            credentials: "{% if credentials | length>0 %}{{ credentials | split(',') }}{% endif %}"

        - name: update project for scm allow_override and scm_update_on_launch
          awx.awx.project:
            name: "{{ project_var }}"
            state: present
            description: "{{ project_info[0].description }}"
            organization: "{{ project_info[0].organization }}"
            default_environment: "{{ project_info[0].default_environment }}"
            scm_type: "{{ project_info[0].scm_type }}"
            scm_url: "$scm_url"
            scm_branch: "{{ project_info[0].scm_branch }}"
            scm_refspec: "{{ scm_refspec }}"
            # credential: "{{ project_info[0].credential }}"
            scm_clean: "{{ project_info[0].scm_clean }}"
            scm_delete_on_update: "{{ project_info[0].scm_delete_on_update }}"
            scm_track_submodules: "{{ project_info[0].scm_track_submodules }}"
            scm_update_on_launch: True
            allow_override: True
            validate_certs: "$CONTROLLER_VERIFY_SSL"

        # This task is only updating ask_scm_branch_on_launch
        - name: update job template to turn ask_scm_branch_on_launch
          awx.awx.job_template:
            allow_simultaneous: "{{ template_info[0].allow_simultaneous }}"
            ask_credential_on_launch: "{{ template_info[0].ask_credential_on_launch }}"
            ask_diff_mode_on_launch: "{{ template_info[0].ask_diff_mode_on_launch }}"
            ask_inventory_on_launch: "{{ template_info[0].ask_diff_mode_on_launch }}"
            ask_job_type_on_launch: "{{ template_info[0].ask_job_type_on_launch }}"
            ask_limit_on_launch: "{{ template_info[0].ask_limit_on_launch }}"
            ask_scm_branch_on_launch: True
            ask_skip_tags_on_launch: "{{ template_info[0].ask_skip_tags_on_launch }}"
            ask_tags_on_launch: "{{ template_info[0].ask_tags_on_launch }}"
            ask_variables_on_launch: "{{ template_info[0].ask_variables_on_launch }}"
            ask_verbosity_on_launch: "{{ template_info[0].ask_verbosity_on_launch }}"
            become_enabled: "{{ template_info[0].become_enabled }}"
            credentials: "{{ credentials | default(omit, true) }}"
            description: "{{ template_info[0].description }}"
            diff_mode: "{{ template_info[0].diff_mode }}"
            execution_environment: "{{ template_info[0].execution_environment }}"
            extra_vars: "{% if not template_info[0].extra_vars | from_yaml %}{}{% else %}blah{% endif %}"
            force_handlers: "{{ template_info[0].force_handlers }}"
            forks: "{{ template_info[0].forks }}"
            host_config_key: "{{ template_info[0].host_config_key }}"
            inventory: "{{ template_info[0].inventory }}"
            job_slice_count: "{{ template_info[0].job_slice_count }}"
            job_tags: "{{ template_info[0].job_tags }}"
            job_type: "{{ template_info[0].job_type }}"
            limit: "{{ template_info[0].limit }}"
            name: "{{ template_info[0].name }}"
            organization: "{{ template_info[0].organization }}"
            playbook: "{{ template_info[0].playbook }}"
            project: "{{ template_info[0].project }}"
            scm_branch: "{{ template_info[0].scm_branch }}"
            skip_tags: "{{ template_info[0].skip_tags }}"
            start_at_task: "{{ template_info[0].start_at_task }}"
            survey_enabled: "{{ template_info[0].survey_enabled }}"
            timeout: "{{ template_info[0].timeout }}"
            use_fact_cache: "{{ template_info[0].use_fact_cache }}"
            verbosity: "{{ template_info[0].verbosity }}"
            webhook_credential: "{{ template_info[0].webhook_credential | default(omit, true) }}"
            webhook_service: "{{ template_info[0].webhook_service }}"
            validate_certs: "$CONTROLLER_VERIFY_SSL"

      #when: project_var|length > 0

    - name: launch a job and wait for the job
      when: job_template_var | length > 0
      block:
        - name: Launch a job template with extra_vars on remote controller instance when project is set
          awx.awx.job_launch:
            job_template: "{{ job_template_var }}"
            extra_vars: "{{ extra_vars |  default(omit, true) }}"
            validate_certs: "$CONTROLLER_VERIFY_SSL"
            scm_branch: "{{ scm_branch |  default(omit, true) }}"
          register: job_output

        - name: Wait for job
          awx.awx.job_wait:
            job_id: "{{ job_output.id }}"
            timeout: 3600
            validate_certs: "$CONTROLLER_VERIFY_SSL"

        - name: retrieve job info
          when: job_template_var|length > 0
          uri:
            url: https://$CONTROLLER_HOST/api/v2/jobs/{{ job_output.id }}/stdout/?format=json
            method: GET
            user: "$CONTROLLER_USERNAME"
            password: "$CONTROLLER_PASSWORD"
            validate_certs: "$CONTROLLER_VERIFY_SSL"
            force_basic_auth: yes
          register: playbook_output

        - name: display Automation controller job output
          debug:
            var: playbook_output.json.content

        - name: copy playbook output from Automation controller to file
          ansible.builtin.copy:
            content: "{{ playbook_output.json.content }}"
            dest: job_output.txt

    - name: launch a workflow and wait for the workflow to finish
      when: workflow_template_var | length > 0
      block:
        - name: Launch a workflow template with extra_vars on remote controller instance when project is set
          awx.awx.workflow_launch:
            workflow_template: "{{ workflow_template_var }}"
            extra_vars: "{{ extra_vars |  default(omit, true) }}"
            validate_certs: "$CONTROLLER_VERIFY_SSL"
            scm_branch: "{{ scm_branch |  default(omit, true) }}"
          register: workflow_output

        - name: print out workflow_output
          debug:
            var: workflow_output

        - name: Wait for workflow
          awx.awx.job_wait:
            job_id: "{{ workflow_output.id }}"
            job_type: workflow_jobs
            timeout: 3600
            validate_certs: "$CONTROLLER_VERIFY_SSL"

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
