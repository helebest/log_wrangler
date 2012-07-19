class log_wrangler::reposetup {
    notice('setting up repos')

  exec { "yum-clean":
    command     => "/usr/bin/yum clean all",
    refreshonly => true;
  }

  yumrepo { 'log_wrangler':
    baseurl    => 'http://logwrangler.mtcode.com/repo/',
    descr      => 'Log Wrangler repo.',
    enabled    => 1,
    gpgcheck   => 0,
    priority   => 5,
    notify     => Exec['yum-clean'],
  }

  package { 'epel-release':
    ensure => installed,
    require => Exec['yum-clean'],
  }
}
