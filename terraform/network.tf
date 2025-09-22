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
  dns_label = "demo"
}

# an internet gateway allows connections to and from the public Internet for public subnets
# you need a NAT gateway for hosts in private subnets to access the Internet, but that's
# not part of this demo
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

# security list allowing SSH only from the dedicated IP/CIDR
resource "oci_core_security_list" "public_sl_ssh" {
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
  display_name   = "public-subnet"
  defined_tags = {
    "project-namespace.name" = "mabach-doag",
    "Administration.Creator" = "martin.b.bach@oracle.com"
  }
  cidr_block                 = var.public_subnet_cidr
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_security_list.public_sl_ssh.id]
  prohibit_public_ip_on_vnic = false
  dns_label                  = "pub"
}
