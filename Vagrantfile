# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.box = "netsensia/ubuntu-trusty64"
    config.vm.network :private_network, ip: '10.0.0.100', :adapter => 2
    config.vm.network "forwarded_port", guest: 80, host: 80

    config.ssh.forward_x11 = true

    config.vm.provision :shell, :path => "./bootstrap.sh"

    config.vm.provider :vmware_fusion do |vb|
      vb.customize [ "modifyvm", :id, "--memory", 4128, "--cpus", 2, "--vram", 16, "--natdnshostresolver1", "on"]
    end
end
