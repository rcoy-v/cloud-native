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
      pods_cidr     = var.cidr_blocks.pods
      services_cidr = var.cidr_blocks.services
    }
    service_lb_subnet_ids = [
      oci_core_subnet.load_balancers.id
    ]
  }
}

output "cloud_native_cluster_ocid" {
  value = oci_containerengine_cluster.cloud_native.id
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
