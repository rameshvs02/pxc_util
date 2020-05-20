Vagrant.configure("2") do |config|
  config.vm.define "node1" do |node1|
    node1.vm.box = "centos/7"
    node1.vm.hostname = 'node1.local'
    node1.vm.network :private_network, ip: "192.168.100.10"
    node1.vm.provision "shell", inline: "/bin/bash /vagrant/pxc80/setup.sh 1"
    config.vm.provider :virtualbox do |vb|
      vb.memory = 4098
      vb.cpus = 2
    end
  end

  config.vm.define "node2" do |node2|
    node2.vm.box = "centos/7"
    node2.vm.hostname = 'node2.local'
    node2.vm.network :private_network, ip: "192.168.100.20"
    node2.vm.provision "shell", inline: "/bin/bash /vagrant/pxc80/setup.sh 2"
    config.vm.provider :virtualbox do |vb|
      vb.memory = 4098
      vb.cpus = 2
    end
  end

  config.vm.define "node3" do |node3|
    node3.vm.box = "centos/7"
    node3.vm.hostname = 'node3.local'
    node3.vm.network :private_network, ip: "192.168.100.30"
    node3.vm.provision "shell", inline: "/bin/bash /vagrant/pxc80/setup.sh 3"
    config.vm.provider :virtualbox do |vb|
      vb.memory = 4098
      vb.cpus = 2
    end
  end

  config.vm.define "proxysql" do |proxysql|
    proxysql.vm.box = "centos/7"
    proxysql.vm.hostname = 'proxysql-local'
    proxysql.vm.network :private_network, ip: "192.168.100.40"
    proxysql.vm.provision "shell", inline: "/bin/bash /vagrant/proxysql/setup-proxysql2.sh"
    config.vm.provider :virtualbox do |vb|
      vb.memory = 4048
      vb.cpus = 2
    end
  end
end
