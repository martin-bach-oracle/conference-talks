# ------------------------------------------------------------------------------------------------
# provider details

terraform {
  required_version = ">= 1.13.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.key_fingerprint
  region           = var.oci_region
}

# ------------------------------------------------------------------------------------------------
# data sources

# get the list of availability domains
data "oci_identity_availability_domains" "local_ads" {
  compartment_id = var.compartment_ocid
}


# ------------------------------------------------------------------------------------------------
# compute

resource "oci_core_instance" "doag_compute_instance" {

  # hard-coded to AD2 (the third one in FFM)
  availability_domain = data.oci_identity_availability_domains.local_ads.availability_domains.2.name
  compartment_id      = var.compartment_ocid

  shape = "VM.Standard.E5.Flex"
  shape_config {

    memory_in_gbs = 32
    ocpus         = 4
  }

  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }

  create_vnic_details {

    assign_public_ip = false
    hostname_label   = "doag"
    subnet_id        = oci_core_subnet.private_subnet.id

  }

  agent_config {

    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config {
      desired_state = "ENABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

  display_name = "doag-demohost"

  metadata = {
    "ssh_authorized_keys" = file(var.ssh_public_key_path)
  }

  source_details {

    # https://docs.oracle.com/en-us/iaas/Content/Compute/References/images.htm
    source_id   = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa6n45jpagnnbup4rfglrbr6g2wk4mwna72tfnsmxcyor5poevokha"
    source_type = "image"

    boot_volume_size_in_gbs = 250
  }

  preserve_boot_volume = false
}