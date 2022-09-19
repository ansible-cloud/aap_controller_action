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

pull/1/head

# scm_url e.g. https://github.com/ansible-cloud/aap_controller_action
# scm_branch e.g. pull/1/head (for PR #1)
# scm_refspec e.g. refs/pull/1/head:refs/remotes/origin/pull/1/head

scm_url="https://github.com/$GITHUB_REPOSITORY"
echo "scm_url is $scm_url"

scm_branch="pull/$pull_request_event/head"
echo "scm_branch is $scm_branch"

# scm_refspec="refs/pull/$pull_request_event/head:refs/remotes/origin/pull/$pull_request_event/head"
# echo "scm_refspec is $scm_refspec"



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
        project_var: "$CONTROLLER_PROJECT"
        extra_vars: "$EXTRA_VARS"
        scm_url: "$scm_url"
        scm_branch: "$scm_branch"
        # scm_refspec: "$scm_refspec"
        scm_refspec: "refs/pull/*:refs/remotes/origin/pull/*"

    - name: print out extra_vars
      debug:
        msg:
          - "extra vars are {{ extra_vars }}"

    - name: project update and sync
      block:
      - name: retrieve info on existing specified project in Automation controller
        set_fact:
          project_info: "{{ query('awx.awx.controller_api', 'projects', verify_ssl=$CONTROLLER_VERIFY_SSL, query_params={ 'name': 'test project' }) }}"

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

      - name: update project to point at pull request
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
          scm_update_on_launch: "{{ project_info[0].scm_update_on_launch }}"
          allow_override: True

      - name: sync project update
        awx.awx.project_update:
          project: "{{ project_var }}"
          validate_certs: "$CONTROLLER_VERIFY_SSL"
          wait: true
      when: project_var|length > 0

    - name: Launch a job template with extra_vars on remote controller instance
      when: job_template_var|length > 0
      awx.awx.job_launch:
        job_template: "{{ job_template_var }}"
        extra_vars: "$EXTRA_VARS"
        validate_certs: "$CONTROLLER_VERIFY_SSL"
        scm_branch: "{{ scm_branch }}"
      register: job_output

    - name: Wait for job
      when: job_template_var|length > 0 or workflow_template_var|length > 0
      awx.awx.job_wait:
        job_id: "{{ job_output.id }}"
        timeout: 3600
        validate_certs: "$CONTROLLER_VERIFY_SSL"

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

    - name: copy playbook output from Automation controller to file
      when: job_template_var|length > 0 or workflow_template_var|length > 0
      ansible.builtin.copy:
        content: "{{ playbook_output.json.content }}"
        dest: job_output.txt

    # - name: revert project settings back to original
    #   awx.awx.project:
    #     name: "{{ project_var }}"
    #     state: present
    #     description: "{{ project_info[0].description }}"
    #     organization: "{{ project_info[0].organization }}"
    #     default_environment: "{{ project_info[0].default_environment }}"
    #     scm_type: "{{ project_info[0].scm_type }}"
    #     scm_url: "{{ project_info[0].scm_url }}"
    #     scm_branch: "{{ project_info[0].scm_branch }}"
    #     scm_refspec: "{{ project_info[0].scm_refspec }}"
    #     # credential: "{{ project_info[0].credential }}"
    #     scm_clean: "{{ project_info[0].scm_clean }}"
    #     scm_delete_on_update: "{{ project_info[0].scm_delete_on_update }}"
    #     scm_track_submodules: "{{ project_info[0].scm_track_submodules }}"
    #     scm_update_on_launch: "{{ project_info[0].scm_update_on_launch }}"
    #     allow_override: "{{ project_info[0].allow_override }}"
    #   when: project_var|length > 0

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
