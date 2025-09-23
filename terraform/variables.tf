# --------------------------------------------------------------------- variables

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "key_fingerprint" {}
variable "private_key_path" {}
variable "oci_region" {}
variable "local_laptop_ip" {}
variable "compartment_ocid" {}
variable "ssh_public_key_path" {}
variable "ssh_windows_key_path" {}
variable "vcn_cidr" {
  default = "192.168.0.0/16"
}

variable "public_subnet_cidr" {
  default = "192.168.0.0/24"
}

variable "private_sn_cidr_block" {
  default = "192.168.1.0/24"
}