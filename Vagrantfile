VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion/ubuntu-14.04-amd64"

  config.vm.provider "vmware_fusion" do |provider|
    provider.vmx['memsize'] = 1024
    provider.vmx['numvcpus'] = 2
  end

  config.vm.synced_folder ENV['HOME'], '/mnt'
end
