Vagrant::Config.run do |config|
  # centos 6 is our base
  config.vm.box = "centos62"

  # where to grab the base box if not available locally
  config.vm.box_url = "http://logwrangler.mtcode.com/centos62.box"

  # switch this if you'd like to grab a real IP
  #config.vm.network :bridged

  # uncomment to show vm while running
  #config.vm.boot_mode = :gui

  # forwarded ports for external access
  config.vm.forward_port 80, 8080
  config.vm.forward_port 55672, 55672
  config.vm.forward_port 9200, 9200
  config.vm.forward_port 6999, 6999

  # configure with puppet
  #config.vm.provision :puppet, :module_path => "puppet", :options => "--noop" do |puppet|
  if ENV['PROVISION']
    config.vm.provision :puppet, :module_path => "puppet" do |puppet|
      puppet.manifests_path = "puppet"
      puppet.manifest_file = "log_wrangler.pp"
    end
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
