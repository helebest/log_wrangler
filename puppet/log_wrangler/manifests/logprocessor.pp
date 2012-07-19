class log_wrangler::logprocessor (
  $es_cluster_name,
  $rabbitmq_cluster_nodes,
  $es_min_mem,
  $es_max_mem,
  $es_indices_max_days,
  $es_indices_match_pattern,
  $allowed_networks
) {

  # get everything installed
  package {
    "grok": ensure => installed;
    "logstash": ensure => installed;
    "rabbitmq-server": ensure => "2.8.2-1";
    "elasticsearch": ensure => installed;
    "elasticsearch-plugin-river-rabbitmq": ensure => installed;
    "elasticsearch-utils": ensure => latest;
    "kibana": ensure => installed;
    "httpd": ensure => installed;
  }

  # RABBITMQ
  group { "rabbitmq":
    ensure => present
  }
  user { "rabbitmq":
    ensure => present,
    gid => "rabbitmq",
    membership => minimum,
    home => "/var/lib/rabbitmq",
    shell => "/bin/bash",
    require => Group["rabbitmq"],
  }

  file { "/etc/rabbitmq":
    ensure => "directory",
    owner => 'root',
    group => 'root',
  }

  file { "/etc/rabbitmq/rabbitmq.config":
    before => Package["rabbitmq-server"],
    content => template("log_wrangler/rabbitmq.config.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    ensure => file,
    notify => Service["rabbitmq-server"],
  }

  file { "/var/lib/rabbitmq/":
    ensure => "directory",
  }

  # this cookie identifies this rabbitmq cluster and must be the same across
  # all nodes in the cluster
  file { "/var/lib/rabbitmq/.erlang.cookie":
    before => Package["rabbitmq-server"],
    source => "puppet:///modules/log_wrangler/rabbitmq.erlang.cookie",
    owner => 'rabbitmq',
    group => 'rabbitmq',
    mode => '0400',
    ensure => file,
    notify => Exec["force-stop-rabbitmq"],
  }

  # script to ensure rabbitmq is fully stopped
  file { "/usr/local/bin/force-stop-rabbitmq":
    source => "puppet:///modules/log_wrangler/force-stop-rabbitmq",
    owner => 'root',
    group => 'root',
    mode => '0755',
    ensure => file,
  }

  # have to kill rabbit when changing the erlang cookie.  If it's changed
  # while rabbitmq is up, then the node won't respond to command because
  # rabbitmqctl relies on that cookie to find the rabbitmq instance  
  exec { "force-stop-rabbitmq":
    command => "force-stop-rabbitmq",
    path  => ["/usr/local/bin", "/bin", "/usr/bin"],
    logoutput => true,
    refreshonly => true,
  }

  service { "rabbitmq-server":
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
    require => [ Package["rabbitmq-server"], File["/var/lib/rabbitmq/.erlang.cookie"] ]
  }

  # enable the rabbitmq management ui and reload rabbitmq, but only if not already installed
  exec { "rabbitmq-management":
    subscribe => [ Package["rabbitmq-server"] ],
    command => "/usr/sbin/rabbitmq-plugins enable rabbitmq_management && /sbin/service rabbitmq-server reload",
    logoutput => true,
    returns => 0,
    onlyif => "/bin/bash -c \"RET=`/usr/sbin/rabbitmq-plugins list|/bin/grep '\\[E\\] rabbitmq_management'|/usr/bin/wc -l`; exit \\\$RET\"",
  }

  # ELASTICSEARCH
  file { "/etc/elasticsearch":
    ensure => "directory",
    owner => 'root',
    group => 'root',
  }

  file { "/etc/elasticsearch/elasticsearch.yml":
    before => Package["elasticsearch"],
    content => template("log_wrangler/elasticsearch.yml.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    ensure => file,
    notify => Service["elasticsearch"],
  }

  service { "elasticsearch":
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
    require => Package["elasticsearch"]
  }

  # switch out the elasticsearch config
  file { "/etc/rc.d/init.d/elasticsearch":
    source => "puppet:///modules/log_wrangler/elasticsearch.initd",
    owner => 'root',
    group => 'root',
    mode => '0755',
    ensure => file,
    notify => Service["elasticsearch"],
    require => Package["elasticsearch"]
  }

  file { "/etc/sysconfig/elasticsearch":
    content => template("log_wrangler/elasticsearch.sysconfig.erb"),
    owner => 'root',
    group => 'root',
    mode => '0755',
    ensure => file,
    notify => Service["elasticsearch"],
    require => Package["elasticsearch"]
  }

  # need to create the elasticsearch river if it doesn't already exist
  exec { "create-elasticsearch-river":
    subscribe => [ Package["elasticsearch-plugin-river-rabbitmq"] ],
    path => '/bin:/usr/bin',
    command => "sleep 10 && /usr/share/java/elasticsearch/plugins/river-rabbitmq/create-elasticsearch-river",
    logoutput => true,
    returns => 0,
    require => [Service['rabbitmq-server'], Service['elasticsearch'], File['/var/lib/rabbitmq/.erlang.cookie'], Exec['force-stop-rabbitmq']],
  }

  # enable the elasticsearch-head module, but only if not already installed
  exec { "elasticsearch-head":
    command => "/usr/share/java/elasticsearch/bin/plugin -install mobz/elasticsearch-head",
    logoutput => true,
    returns => 0,
    onlyif => "/bin/bash -c \"RET=`/usr/bin/curl -s -X GET 'http://localhost:9200/_plugin/head/'|/bin/grep 'ElasticSearch Head'|/usr/bin/wc -l`; exit \\\$RET\"",
    require => Package["elasticsearch"],
  }

  # add the cron for our index cleanup
  add_cron { 'remove_old_indexes':
    cron_schedule => '*/5 * * * *',
    user      => 'root',
    command     => "/opt/mt/bin/remove-old-indices -pattern $es_indices_match_pattern -keep-max $es_indices_max_days",
  }

  # LOGSTASH
  service { "logstash":
    ensure => running,
    enable => true,
    hasstatus => false,
    hasrestart => true,
    require => [ Package["logstash"], File["/etc/logstash/logstash.conf"] ],
  }

  # tweak the configuration for everything
  file { "/etc/logstash/logstash.conf":
    content => template("log_wrangler/logstash.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    ensure => file,
    notify => Service["logstash"],
    require => Package["logstash"]
  }

  # KIBANA
  service { "httpd":
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
    require => [ Package["httpd"], File["/etc/httpd/conf.d/kibana.conf"], File["/var/www/html/kibana/config.php"] ],
  }

  file { "/etc/httpd/conf.d/kibana.conf":
    content => template("log_wrangler/kibana.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    ensure => file,
    notify => Service["httpd"],
    require => Package["kibana"],
  }

  file { "/var/www/html/kibana/config.php":
    content => template("log_wrangler/config.php.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    ensure => file,
    require => Package["kibana"],
  }

  define add_cron ($command, $cron_schedule='* * * * *', $user='root', $ensure = 'present') {
    file { "/etc/cron.d/${name}":
      content => "$cron_schedule $user $command\n",
      ensure  => $ensure,
      owner => 'root',
      group => 'root',
    }
  }
}

