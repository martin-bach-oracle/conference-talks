# Ansible

The Ansible Playbook does a few things:

1. Configures the Oracle Linux 9 host for Oracle Database 19c
1. Installs Oracle Database 19.28 using AutoUpgrade
1. Installs and configures Oracle REST Data Services

To run this playbook, use the following snippet

```sh
ansible-playbook -vi <inventory file> main.yml -e dba_password=redacted
```

You must provide an extra variable to this play to indicate the DBA password.

Variables for this playbook are stored in different places for the sake of demonstration:

- group_vars contains the variables for the Oracle Database installation
- ords/vars/main.yml contains the relevant variables for ORDS

Note this is not official code, and suitable for my conference talk _only_.