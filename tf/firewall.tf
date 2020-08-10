locals {
  # Security list Terraform resources use registered protocol numbers
  # https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
  TCP_PROTOCOL = "6"
}

resource "oci_core_security_list" "workers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "workers"

  # Allow all traffic between OKE worker nodes
  ingress_security_rules {
    protocol = "all"
    source   = var.cidr_blocks.workers
  }

  # Allow load balancers to node port range
  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
    source   = var.cidr_blocks.load_balancers
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  # Allow load balancer health checks to kube-proxy
  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
    source   = var.cidr_blocks.load_balancers
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  # Allow OKE worker nodes to response to traffic and internet access
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}

resource "oci_core_security_list" "load_balancers" {
  compartment_id = oci_identity_compartment.cloud_native.id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "loadbalancers"

  # Allow public http traffic
  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Allow public https traffic
  ingress_security_rules {
    protocol = local.TCP_PROTOCOL
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow load balancer subnet to response to traffic
  egress_security_rules {
    protocol    = local.TCP_PROTOCOL
    destination = "0.0.0.0/0"
  }
}
