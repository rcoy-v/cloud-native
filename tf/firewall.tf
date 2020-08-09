locals {
  ICMP_PROTOCOL = "1"
  TCP_PROTOCOL  = "6"
}

resource "oci_core_security_list" "workers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "workers"

  ingress_security_rules {
    protocol = "all"
    source   = var.cidr_blocks.workers
  }

  ingress_security_rules {
    protocol = local.ICMP_PROTOCOL
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
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

  # When a k8s LoadBalancer service is deployed, it will configure additional security list rules.
  # Those are for the dynamic health checks for the backend.
  # Don't undo those if terraform apply is run later.
  lifecycle {
    ignore_changes = [
      ingress_security_rules
    ]
  }
}

resource "oci_core_security_list" "load_balancers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "loadbalancers"

  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol    = local.TCP_PROTOCOL
    destination = "0.0.0.0/0"
  }

  # When a k8s LoadBalancer service is deployed, it will configure additional security list rules.
  # Those are for the dynamic health checks for the backend.
  # Don't undo those if terraform apply is run later.
  lifecycle {
    ignore_changes = [
      egress_security_rules
    ]
  }
}
