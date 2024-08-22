resource "instaclustr_opensearch_cluster_v2" "example" {
  data_nodes {
    node_count = 3
    node_size = "SRH-DEV-t4g.small-5"
  }

  pci_compliance_mode = false
  opensearch_version = "2.12.0"
  knn_plugin = true

  data_centre {
    cloud_provider = "AWS_VPC"
    name = "AWS_VPC_US_EAST_1"
    network = "10.1.0.0/16"
    number_of_racks = 3
    private_link = false
    region = "US_EAST_1"
  }

  load_balancer = true
  private_network_cluster = false
  name = "rostyslp-test"
  cluster_manager_nodes {
    dedicated_manager = true
    node_size = "SRH-DM-DEV-t4g.small-5"
  }

  index_management_plugin = false
  alerting_plugin = false
  icu_plugin = false
  asynchronous_search_plugin = false
  reporting_plugin = false
  sql_plugin = false
  notifications_plugin = false
  anomaly_detection_plugin = false
  sla_tier = "NON_PRODUCTION"
}

resource "instaclustr_cluster_network_firewall_rules_v2" "example" {
  cluster_id = instaclustr_opensearch_cluster_v2.example.id
  firewall_rule {
    network = "${module.vpc.nat_public_ips[0]}/32"
    type = "OPENSEARCH"
  }
}