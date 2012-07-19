class log_wrangler::firewall {
  include log_wrangler::firewall::pre
  include log_wrangler::firewall::post

  firewall { "200 INPUT allow all to ssh ports":
    action => 'accept',
    dport  => '22',
  }   

  firewall { "200 INPUT allow all to http ports":
    action => 'accept',
    dport  => '80',
  }   

  firewall { "200 INPUT allow all to ES web ports":
    action => 'accept',
    dport  => '9200',
  }   

  firewall { "200 INPUT allow all to rabbitmq management ports":
    action => 'accept',
    dport  => '55672',
  }   

  firewall { "200 INPUT allow all to logstash netcat ports":
    action => 'accept',
    dport  => '6999',
  }   
}
