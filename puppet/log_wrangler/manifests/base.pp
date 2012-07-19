class log_wrangler::base {

  if ( $lsbmajdistrelease >= '6' ) {
    # Set user vmail and group vmail to have unlimited number of processes on Centos 6++
    file { "/etc/security/limits.d/90-nproc.conf":
      source => 'puppet:///modules/log_wrangler/security/limits.d/90-nproc.conf',
      owner => 'root',
      mode => '0644',
      group => 'root',
      ensure  => file,
    }

    # Set default sysctl with disabled ipv6
    file { "/etc/sysctl.conf":
      source => "puppet:///modules/log_wrangler/sysctl.conf.$lsbdistid.$lsbmajdistrelease",
      owner => 'root',
      mode => '0644',
      group => 'root',
      ensure  => file,
    }

    # disable ipv6 now
    exec { "disable_ipv6":
      command => "/bin/echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 && /bin/echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6",
      logoutput => true,
    }
  }

# MR    realize (
# MR        User['vmail'],
# MR        Group['vmail'],
# MR    )
# MR
# MR    File {
# MR        owner => 'vmail',
# MR        group => 'vmail',
# MR    }

  # keep updatedb from searching some paths, like /home and /var/log
  file { "/etc/updatedb.conf":
    source => 'puppet:///modules/log_wrangler/updatedb.conf',
    owner => 'root',
    mode => '0644',
    group => 'root',
    ensure  => file,
  }

# MR  package {"nscd": ensure => installed;}
# MR  service {"nscd": require => Package["nscd"]}
# MR
# MR  monit::common::complex_service { 'nscd':
# MR    pidbase => '/var/run/nscd',
# MR    pidfile => 'nscd.pid',
# MR    require => Service['nscd'],
# MR  }
}
