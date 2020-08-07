provider "oci" {
  version      = "3.88"
  tenancy_ocid = var.tenancy_ocid
}

resource "oci_identity_compartment" "test" {
  enable_delete  = true
  compartment_id = var.tenancy_ocid
  description    = "test"
  name           = "test"
}
