# ------------------------------------------------------------------------------------------------
# networking

resource "oci_core_vcn" "demovcn" {
  compartment_id = var.compartment_ocid
  display_name   = "demovcn"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  # Use modern cidr_blocks form
  cidr_blocks = [var.vcn_cidr]
  dns_label   = "demo"
}

# an internet gateway allows connections to and from the public Internet for public subnets
# you need a NAT gateway for hosts in private subnets to access the Internet
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "demovcn-igw"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  enabled = true
  vcn_id  = oci_core_vcn.demovcn.id
}

resource "oci_core_nat_gateway" "ngw" {

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  display_name = "demovcn-ngw"
}

# public routing table
resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  display_name   = "demovcn-public-rt"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }

  route_rules {
    description       = "Default route to the Internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# private route table
resource "oci_core_route_table" "private_rt" {

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  display_name   = "private subnet route table"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }

  route_rules {

    description       = "allow system updates (acceptable only for this quick demo!)"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }

  route_rules {

    description       = "Allow access via bastion service"
    destination       = lookup(data.oci_core_services.sgw_services.services.0, "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}

# service gateway

data "oci_core_services" "sgw_services" {

}

resource "oci_core_service_gateway" "sgw" {

  compartment_id = var.compartment_ocid
  services {

    # service 0 means all services, not just block storage ...
    service_id = data.oci_core_services.sgw_services.services.0.id
  }

  vcn_id = oci_core_vcn.demovcn.id

  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  display_name = "SGW (required for the Bastion Service)"
}

# security list allowing SSH only from the dedicated IP/CIDR
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  display_name   = "demovcn-public-ssh-inbound"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }

  # allow all egress
  egress_security_rules {
    description      = "Allow all egress"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  # ingress SSH 22 from dedicated source
  ingress_security_rules {
    description = "Allow SSH from dedicated source"
    protocol    = "6" # TCP
    source      = var.local_laptop_ip
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }
}

# the public subnet itself, uses the previously create security list
resource "oci_core_subnet" "public_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  display_name   = "public subnet"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  cidr_block                 = var.public_subnet_cidr
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_security_list.public_sl.id]
  prohibit_public_ip_on_vnic = false
  dns_label                  = "pub"
}

# private subnet: security list
resource "oci_core_security_list" "private_sl" {

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id

  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  display_name = "private subnet security list"

  egress_security_rules {

    destination = "0.0.0.0/0"
    protocol    = "6"

    description = "system updates (http)"
    tcp_options {

      max = 80
      min = 80

    }
  }

  egress_security_rules {

    destination = "0.0.0.0/0"
    protocol    = "6"

    description = "system updates (https)"
    tcp_options {

      max = 443
      min = 443

    }
  }

  egress_security_rules {

    destination = var.private_sn_cidr_block
    protocol    = "6"

    description      = "SSH outgoing"
    destination_type = ""

    stateless = false
    tcp_options {

      max = 22
      min = 22

    }
  }

  ingress_security_rules {

    protocol = "6"
    source   = var.private_sn_cidr_block

    description = "SSH inbound"

    source_type = "CIDR_BLOCK"
    tcp_options {

      max = 22
      min = 22

    }

  }
}
resource "oci_core_subnet" "private_subnet" {

  cidr_block     = var.private_sn_cidr_block
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.demovcn.id
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  display_name               = "private subnet"
  dns_label                  = "priv"
  prohibit_public_ip_on_vnic = true
  prohibit_internet_ingress  = true
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids = [
    oci_core_security_list.private_sl.id
  ]
}