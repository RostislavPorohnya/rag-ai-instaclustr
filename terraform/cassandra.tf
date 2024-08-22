resource "instaclustr_cassandra_cluster_v2" "example" {
  pci_compliance_mode = false
  data_centre {
    client_to_cluster_encryption = false
    cloud_provider = "AWS_VPC"
    continuous_backup = true
    name = "MyTestDataCentre1"
    network = "10.2.0.0/16"
    node_size = "CAS-DEV-t4g.small-5"
    number_of_nodes = 3
    private_ip_broadcast_for_discovery = false
    region = "US_EAST_1"
    replication_factor = 3
  }

  private_network_cluster = false
  cassandra_version = "4.0.13"
  lucene_enabled = false
  password_and_user_auth = false
  name = "rostyslp-test"

  sla_tier = "NON_PRODUCTION"
}

resource "instaclustr_cluster_network_firewall_rules_v2" "example-cassandra" {
  cluster_id = instaclustr_cassandra_cluster_v2.example.id
  firewall_rule {
    network = "${module.vpc.nat_public_ips[0]}/32"
    type = "CASSANDRA_CQL"
  }
  depends_on = [instaclustr_cassandra_cluster_v2.example]
}
