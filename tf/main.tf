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

resource "oci_core_vcn" "oke" {
  compartment_id = oci_identity_compartment.cloud_native.id
  cidr_block     = "172.16.0.0/16"
  display_name   = "OKE"
  dns_label      = "oke"
}

resource "oci_core_subnet" "workers" {
  cidr_block                 = "172.16.0.0/24"
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
  cidr_block     = "172.16.1.0/24"
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

resource "oci_core_security_list" "workers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "workers"

  ingress_security_rules {
    protocol = "all"
    source   = "172.16.0.0/24"
  }

  ingress_security_rules {
    protocol = "1"
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}

resource "oci_core_security_list" "load_balancers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "loadbalancers"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }
}

resource "oci_containerengine_cluster" "cloud_native" {
  compartment_id     = oci_identity_compartment.cloud_native.id
  kubernetes_version = "v1.16.8"
  name               = "cloud-native"
  vcn_id             = oci_core_vcn.oke.id

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [
      oci_core_subnet.load_balancers.id
    ]
  }
}

resource "oci_containerengine_node_pool" "standard" {
  cluster_id         = oci_containerengine_cluster.cloud_native.id
  compartment_id     = oci_identity_compartment.cloud_native.id
  kubernetes_version = "v1.16.8"
  name               = "standard"
  node_shape         = "VM.Standard2.2"

  initial_node_labels {
    key   = "cloud-native/node-pool"
    value = "standard"
  }

  node_config_details {
    size = 2
    placement_configs {
      availability_domain = "voGB:PHX-AD-1"
      subnet_id           = oci_core_subnet.workers.id
    }
    placement_configs {
      availability_domain = "voGB:PHX-AD-2"
      subnet_id           = oci_core_subnet.workers.id
    }
    placement_configs {
      availability_domain = "voGB:PHX-AD-3"
      subnet_id           = oci_core_subnet.workers.id
    }
  }

  node_source_details {
    image_id    = "ocid1.image.oc1.phx.aaaaaaaa75jewsxs5j5lwtucurynvmf6aomgkm5ty33c23vb6ouxxoj2tu3q"
    source_type = "IMAGE"
  }
}
