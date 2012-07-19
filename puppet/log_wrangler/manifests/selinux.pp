class log_wrangler::selinux {

  file { "/usr/local/selinux":
    ensure => directory
  }

  file { "/usr/local/bin/compile_selinux.sh":
    mode => 0755,
    source => "puppet:///modules/log_wrangler/selinux/compile_selinux.sh",
  }

  define install_selinux_policy () {

    file { "/usr/local/selinux/$name.te":
      mode => 0600,
      source => "puppet:///modules/log_wrangler/selinux/$name.$lsbdistid$lsbmajdistrelease.te",
      notify => Exec["compile_selinux-$name"],
      require => File["/usr/local/selinux"]
    }

    exec { "compile_selinux-$name":
      command => "/usr/local/bin/compile_selinux.sh /usr/local/selinux/$name.te",
      refreshonly => true,
      notify => Exec["install_selinux-$name"],
      require =>  [File["/usr/local/selinux/$name.te"], File["/usr/local/bin/compile_selinux.sh"]]
    }

    exec { "install_selinux-$name":
      command => "/usr/sbin/semodule -i /usr/local/selinux/$name.pp",
      refreshonly => true,
      require =>  [File["/usr/local/selinux/$name.te"], File["/usr/local/bin/compile_selinux.sh"]]
    }

#     selmodule { "$name":
#       name => $name,
#       ensure => present,
#       selmoduledir => "/usr/local/selinux",
#       syncversion => true
#     }

  }

  install_selinux_policy {"logwrangler":}

  file { "/etc/selinux/config":
    mode   => '0644',
    group  => 'root',
    owner  => 'root',
    source => "puppet:///modules/log_wrangler/selinux/config.selinux",
    require => Package["selinux-policy"]
  }

  package { "selinux-policy":
    ensure => installed,
  }

  exec { "selinux-enforce-on":
    command => "/bin/echo '1' > /selinux/enforce",
    unless  => "/bin/grep 1 /selinux/enforce",
    require => File["/etc/selinux/config"]
  }
}

