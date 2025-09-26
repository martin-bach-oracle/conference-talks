resource "oci_bastion_bastion" "doag_bastionsrv" {

  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id = oci_core_subnet.private_subnet.id

  client_cidr_block_allow_list = [
    var.local_laptop_ip
  ]

  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }

  name = "doagbastionsrv"
}

resource "oci_bastion_session" "doag_bastionsession" {

  bastion_id = oci_bastion_bastion.doag_bastionsrv.id

  key_details {

    public_key_content = file(var.ssh_public_key_path)
  }

  target_resource_details {

    session_type       = "PORT_FORWARDING"
    target_resource_id = oci_core_instance.doag_compute_instance.id

    target_resource_port                       = "22"
  }

  session_ttl_in_seconds = 7200

  display_name = "bastionsession-private-host"
}

output "connection_details" {
  value = oci_bastion_session.doag_bastionsession.ssh_metadata.command
}