# DOAG 11/2025: Automating all the things

This branch accompanies a presentation I gave at the 2025 DOAG conference. It demonstrates using Terraform and Ansible together to provision an Oracle Cloud Infrastructure (OCI) host and configure it with Oracle Database and Oracle REST Data Services (ORDS).

## Terraform

The `terraform` directory defines the OCI infrastructure for the demo:

- `main.tf` configures the OCI provider, looks up availability domains, and creates an Oracle Linux demo compute instance in the private subnet. The instance uses a flexible shape, a 250 GB boot volume, and the supplied SSH public key.
- `network.tf` creates a VCN with public and private subnets, internet, NAT, and service gateways, route tables, and security lists. The demo host has no public IP; its private subnet allows outbound HTTP and HTTPS for updates and routes internet traffic through the NAT gateway.
- `bastion.tf` creates an OCI Bastion and a port-forwarding session to the host's SSH port. Terraform outputs the SSH command for that session.
- `variables.tf` declares OCI credentials, compartment and region, SSH key paths, the allowed client IP/CIDR, and network CIDRs. Supply environment-specific values in a local `.tfvars` file, which is excluded from version control or use environment variables instead.

Together, these resources provide a private host that can be reached over SSH through the Bastion service. The public subnet's security list permits SSH only from `local_laptop_ip`. The network routes and broad demo permissions are intended for this conference example and should be reviewed before reuse.

## Ansible

The `ansible` directory configures the provisioned host and installs the database and ORDS. The entry point is `site.yml`, which targets the `demo` inventory group, checks the operating system and architecture, requires `dba_password`, and runs three tagged roles in order:

1. `hostconfig` sets SELinux to permissive mode for the demo, installs required packages (including the Oracle Database preinstallation RPM and Java versions used by the installation steps), and extends the root LVM volume when the expected disk layout has room for another partition.
2. `database` uses AutoUpgrade to create an Oracle Database 19c home with Release Update 19.28, creates the `ORCL` container database and `PDB1`, and installs a systemd service for the database and listener.
3. `ords` installs ORDS 25.3 against the CDB, configures it as a systemd service, enables the `APIUSER` schema in `PDB1`, and creates the sample `SCOTT` schema and tables. It also configures the `C##DBAPI_CDB_ADMIN` account and ORDS `devops` user for the PDB lifecycle management API.

Role task files are under `hostconfig/tasks`, `database/tasks`, and `ords/tasks`. Their Jinja templates generate AutoUpgrade and SQL scripts plus the database and ORDS systemd units. Shared database paths are in `group_vars/all.yml`; ORDS paths and version are in `ords/vars/main.yml`. `requirements.txt` lists the Ansible and Python dependencies, while `hosts` is an example inventory pointing to `127.0.0.1:2222` through an SSH tunnel.

From the `ansible` directory, the playbook can be run with the supplied inventory and required DBA password:

```sh
ansible-playbook -i hosts site.yml -e dba_password='<demo-password>'
```

The roles can be selected with `--tags hostconfig`, `--tags database`, or `--tags ords`. The playbook assumes Oracle Linux 9 on x86-64 and a compatible OCI boot-volume/LVM layout. It is conference-demo code: in particular, SELinux is made permissive, and the playbook uses the DBA password for several demo accounts. Do not use these settings unchanged in production.
