class log_wrangler (
  $setup_repo = true,
  $rabbitmq_cluster_nodes = [],
  $es_cluster_name = 'default',
  $es_min_mem = '512m',
  $es_max_mem = '512m',
  $es_indices_max_days = '7',
  $es_indices_match_pattern = 'logstash',
  $allowed_networks = ['all']
) {

  class { 'log_wrangler::selinux': } ->
  class { 'log_wrangler::base': } ->
  class { 'log_wrangler::logprocessor':
    es_cluster_name          => $es_cluster_name,
    rabbitmq_cluster_nodes   => $rabbitmq_cluster_nodes,
    es_min_mem               => $es_min_mem,
    es_max_mem               => $es_max_mem,
    es_indices_max_days      => $es_indices_max_days,
    es_indices_match_pattern => $es_indices_match_pattern,
    allowed_networks         => $allowed_networks,
  } ->
  class { 'log_wrangler::firewall': }

  if ($setup_repo) {
    stage { 'log-wrangler-repo-setup': before => Stage['main'] }

    class { 'log_wrangler::reposetup':
      stage => 'log-wrangler-repo-setup',
    }
  }
}
