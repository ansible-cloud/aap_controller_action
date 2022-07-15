# aap_controller_action
Github Action for Ansible Automation Platform - Automation controller



## Example of kicking off an automation job on Automation controller

```
jobs:
  automation_controller_job:
    runs-on: ubuntu-latest
    name: Kick off Automation controller job
    steps:
      - name: Load the ansible-cloud action
        id: controller_job
        uses: ansible-cloud/aap_controller_action@v1.2.8
        with:
          controller_host: ${{ secrets.CONTROLLER_HOST }}
          controller_username: ${{ secrets.CONTROLLER_USERNAME }}
          controller_password: ${{ secrets.CONTROLLER_PASSWORD }}
          job_template: "AWS - ec2 enforce owner tag"
          extra_vars: "your_region=us-west-1"
          validate_certs: false
```

## Setting up your repo to work with this action

You need to setup 3 (three) secrets:

  - CONTROLLER_HOST - this is the DNS name or IP address of your Automation controller.
  - CONTROLLER_USERNAME - the username to access Automation controller
  - CONTROLLER_PASSWORD - the password to access Automation controller

   Example screenshot of Github Secrets

   ![picture of secrests](repo_secrets.png)
