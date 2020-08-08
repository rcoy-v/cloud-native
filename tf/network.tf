resource "oci_core_vcn" "oke" {
  compartment_id = oci_identity_compartment.cloud_native.id
  cidr_block     = var.cidr_blocks.vcn
  display_name   = "OKE"
  dns_label      = "oke"
}

resource "oci_core_subnet" "workers" {
  cidr_block                 = var.cidr_blocks.workers
  compartment_id             = oci_identity_compartment.cloud_native.id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "workers"
  dns_label                  = "workers"
  prohibit_public_ip_on_vnic = true
  security_list_ids = [
    oci_core_security_list.workers.id,
  ]
}

resource "oci_core_subnet" "load_balancers" {
  cidr_block     = var.cidr_blocks.load_balancers
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "loadbalancers"
  dns_label      = "loadbalancers"
  security_list_ids = [
    oci_core_security_list.load_balancers.id
  ]
}

resource "oci_core_nat_gateway" "oke" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "OKE NAT Gateway"
}

resource "oci_core_internet_gateway" "oke" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "OKE Internet Gateway"
}

resource "oci_core_route_table" "workers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "workers"
  route_rules {
    network_entity_id = oci_core_nat_gateway.oke.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "load_balancers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "loadbalancers"
  route_rules {
    network_entity_id = oci_core_internet_gateway.oke.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_route_table_attachment" "workers" {
  route_table_id = oci_core_route_table.workers.id
  subnet_id      = oci_core_subnet.workers.id
}

resource "oci_core_route_table_attachment" "load_balancers" {
  route_table_id = oci_core_route_table.load_balancers.id
  subnet_id      = oci_core_subnet.load_balancers.id
}
