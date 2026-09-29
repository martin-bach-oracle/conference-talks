# DOAG 11/2026: Automating all the things

This branch accompanies a presentation I gave at the 2026 DOAG conference. It demonstrates using Terraform and Ansible together to provision an Oracle Cloud Infrastructure (OCI) host and configure it with Oracle Database and Oracle REST Data Services (ORDS).

## Terraform

The `terraform` directory defines the OCI infrastructure for the demo:

- `main.tf` configures the OCI provider, looks up availability domains, and creates an Oracle Linux 10 demo compute instance in the private subnet. The instance uses a `VM.Standard.E5.Flex` shape with four OCPUs and 32 GB of memory, a 250 GB boot volume, and the supplied SSH public key. It also disables the legacy instance metadata endpoints.
- `network.tf` creates a VCN with one private subnet, NAT and service gateways, a route table, and a security list. The demo host has no public IP; its private subnet allows outbound HTTP and HTTPS for updates through the NAT gateway. The service gateway and its route support OCI Bastion.
- `bastion.tf` creates an OCI Bastion and a port-forwarding session to the host's SSH port. Terraform outputs the SSH command for that session.
- `variables.tf` declares OCI credentials, compartment and region, SSH key paths, the allowed client IP/CIDR, and network CIDRs. Supply environment-specific values in a local `.tfvars` file, which is excluded from version control or use environment variables instead.

Together, these resources provide a private host that can be reached over SSH through the Bastion service. The Bastion service accepts clients from `local_laptop_ip`; the private subnet's security list permits SSH from the private subnet CIDR. The network routes and broad demo permissions are intended for this conference example and should be reviewed before reuse.

To create the OCI resources, use the typical command sequence

- `terraform plan`
- `terraform apply`
- `terraform output`

Carefully review the output at each step before approving! Note that you **will incur cost** if you create the Terraform resources.

## Ansible

The `ansible` directory configures the provisioned host and installs the database and ORDS. The entry point is `site.yml`, which targets the `demo` inventory group, checks the operating system and architecture, requires `dba_password`, and runs three tagged roles in order:

1. `hostconfig` sets SELinux to permissive mode for the demo, installs required packages including `oracle-ai-database-preinstall-26ai` and JDK 21, and extends the root LVM volume when the expected disk layout has room for another partition.
2. `database` uses AutoUpgrade to create an Oracle AI Database 26ai home at `/u01/app/oracle/product/23.26.3`, creates the `ORCL` container database and `PDB1`, and installs a systemd service for the database and listener.
3. `ords` downloads and installs ORDS 26.2.3 against the CDB, configures it as a systemd service, enables the `APIUSER` schema in `PDB1`, and creates the sample `SCOTT` schema and tables. It also configures the `C##DBAPI_CDB_ADMIN` account and ORDS `devops` user for the PDB lifecycle management API.

Role task files are under `hostconfig/tasks`, `database/tasks`, and `ords/tasks`. Their Jinja templates generate AutoUpgrade and SQL scripts plus the database and ORDS systemd units. Shared database paths are in `group_vars/all.yml`; ORDS paths are in `ords/vars/main.yml`. `hosts` is an example inventory pointing to `127.0.0.1:2222` through an SSH tunnel.

### Install Ansible in a virtual environment

Use a Python virtual environment so the demo's Ansible toolchain is isolated from system Python packages. The pinned packages in [`ansible/requirements.txt`](ansible/requirements.txt) are the project's proven installation method.

From the repository root:

```sh
cd ansible
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

This installs Ansible with the exact same release as used during the development of this repository.

### Running the Ansible Playbook

The VM created by Terraform lives in a private subnet, and it requires a bastion session for SSH connection. Use the `terraform output` to get the SSH command, substitute values and connect. After running the SSH command, your session will appear _stuck_. It isn't though, open a second terminal tab and proceed with the Ansible configuration.

If you _cannot_ connect to the bastion service, and you are getting `Connection to host.bastion.<location>.oci.oraclecloud.com closed by remote host` errors most likely your local IP address is wrong and you aren't allowed to connect to the system.

With the virtual environment still active and from the `ansible` directory, run the playbook with the supplied inventory and required DBA password:

```sh
ansible-playbook -i hosts site.yml -e dba_password='<demo-password>'
```

The roles can be selected with `--tags hostconfig`, `--tags database`, or `--tags ords`. The playbook assumes Oracle Linux 10 on x86-64 and a compatible OCI boot-volume/LVM layout. It is conference-demo code: in particular, SELinux is made permissive, and the playbook uses the DBA password for several demo accounts. Do not use these settings unchanged in production.

## Connect to the private VM and clone a PDB with ORDS

The compute instance has no public IP. Terraform creates an OCI Bastion port-forwarding session to the instance's SSH port and returns the connection command as an output. From the `terraform` directory, display that command with:

```sh
terraform output -raw connection_details
```

In the generated command, replace `<privateKey>` with the private key that matches `ssh_public_key_path` and replace `<localPort>` with `2222`. Run the completed command in a terminal and leave it running; it maintains the tunnel and normally produces no further output.

Open a second terminal and connect through the local end of the tunnel:

```sh
ssh -i <private-key> -p 2222 opc@127.0.0.1
```

The Ansible `ords` role installs ORDS on the VM, configures `C##DBAPI_CDB_ADMIN` as the CDB administrator, and creates the ORDS `devops` user with the `SQL Administrator` role required by the [ORDS Pluggable Database Lifecycle Management API](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/26.2/orrst/Authentication-PDB.html). The `devops` password is the `dba_password` supplied when the playbook was run.

On the VM, read the password without echoing it and list the existing PDBs:

```sh
read -rsp 'devops password: ' ORDS_PASSWORD
printf '\n'
ORDS_PDB_URL='http://localhost:8080/ords/_/db-api/stable/database/pdbs'

curl --fail-with-body --silent --show-error \
  --user "devops:${ORDS_PASSWORD}" \
  "${ORDS_PDB_URL}/" | python3 -m json.tool
```

The database is created without explicitly enabling ARCHIVELOG mode. Put the source PDB into read-only mode before cloning it:

```sh
curl --fail-with-body --silent --show-error \
  --user "devops:${ORDS_PASSWORD}" \
  --request PATCH \
  --header 'Content-Type: application/json' \
  --data '{"state":"OPEN","read_only":true,"force":true}' \
  "${ORDS_PDB_URL}/PDB1" | python3 -m json.tool
```

Submit the clone request. The [ORDS 26.2 create-PDB operation](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/26.2/orrst/op-database-pdbs-post.html) accepts `new_pdb_name` and `source_pdb_name` at the PDB collection endpoint:

```sh
curl --fail-with-body --silent --show-error \
  --user "devops:${ORDS_PASSWORD}" \
  --request POST \
  --header 'Content-Type: application/json' \
  --data '{"new_pdb_name":"PDB1CLONE","source_pdb_name":"PDB1"}' \
  "${ORDS_PDB_URL}/" | python3 -m json.tool
```

A successful submission returns HTTP `202 Accepted` and information about the Scheduler job that performs the clone. The operation is asynchronous. After the job finishes, verify that the clone exists:

```sh
curl --fail-with-body --silent --show-error \
  --user "devops:${ORDS_PASSWORD}" \
  "${ORDS_PDB_URL}/PDB1CLONE" | python3 -m json.tool
```

If the clone is not available yet, wait briefly and repeat the verification request. Keep `PDB1` read-only until the clone finishes, then restore it to read/write mode and remove the password from the shell:

```sh
curl --fail-with-body --silent --show-error \
  --user "devops:${ORDS_PASSWORD}" \
  --request PATCH \
  --header 'Content-Type: application/json' \
  --data '{"state":"OPEN","read_write":true,"force":true}' \
  "${ORDS_PDB_URL}/PDB1" | python3 -m json.tool

unset ORDS_PASSWORD
```

`PDB1CLONE` must not already exist. Use a different `new_pdb_name` for subsequent clone operations.
