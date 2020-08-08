provider "oci" {
  version      = "3.88"
  tenancy_ocid = var.tenancy_ocid
}

resource "oci_identity_compartment" "cloud_native" {
  compartment_id = var.tenancy_ocid
  enable_delete  = true
  description    = "Cloud Native"
  name           = "cloud-native"
}
