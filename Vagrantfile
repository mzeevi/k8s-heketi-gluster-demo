# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

VAGRANTFILE_API_VERSION = '2'

vagrant_variable_filename = 'vagrant_variables.yml'
config_file = File.expand_path(File.join(File.dirname(__FILE__), vagrant_variable_filename))

settings = YAML.load_file(config_file)

NBSTN 	  = settings['bastion_vms']
NGLFS 	  = settings['gluster_vms']
MEMORY 	  = settings['memory']
BOX   	  = settings['vagrant_box']
SYNC_DIR  = settings['vagrant_sync_dir']
DEBUG	  = settings['debug']
USER	  = settings['ssh_username']
DISK_SIZE = settings['disk_size_in_mib']
NDISKS	  = settings['num_of_disks']
SUBNET	  = settings['subnet']
DISABLE_SYNCED_FOLDER = settings['vagrant_disable_synced_folder']

$last_ip_digit = 9

ansible_provision = proc do |ansible|
	ansible.playbook = 'site.yml'

	ansible.groups = {
		'bastions'	=> (0..NBSTN - 1).map { |j| "bstn#{j}" },
		'glusterfs'	=> (0..NGLFS - 1).map { |j| "glfs#{j}" }
	}

	if DEBUG then
		ansible.verbose = '-vvvv'
	end

	ansible.limit = 'all'
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.box = BOX
	config.ssh.insert_key = false
	config.ssh.username = USER

  	# Faster bootup. Disables mounting the sync folder for libvirt and virtualbox
  	if DISABLE_SYNCED_FOLDER
    		config.vm.provider :virtualbox do |v,override|
      			override.vm.synced_folder '.', SYNC_DIR, disabled: true
    		end
  	end

	#-----------------------------------------------#
	(0..NGLFS-1).each do |i|
		config.vm.define "glfs#{i}" do |gluster|
                	gluster.vm.hostname = "glfs#{i}"
			gluster.vm.network :private_network,
				ip: "#{SUBNET}.#{$last_ip_digit+=1}"

                	# virtualbox
			gluster.vm.provider :virtualbox do |vb|
			       # create our own controller
				unless File.exist?("disk-test#{i}-0.vdi")
					vb.customize ['storagectl', :id, 
		                                      '--name', 'GLFS Controller',
						      '--add', 'scsi']
				end

				(0..NDISKS-1).each do |d|
					vb.customize ['createhd',
		                                      '--filename', "disk-test#{i}-#{d}",
						      '--size', DISK_SIZE] unless File.exist?("disk-test#{i}-#{d}.vdi")

					vb.customize ['storageattach', :id,
		                                      '--storagectl', 'GLFS Controller',
						      '--port', 3 + d,
						      '--device', 0,
						      '--type', 'hdd',
						      '--medium', "disk-test#{i}-#{d}.vdi"]
				end
                        	vb.customize ['modifyvm', :id, '--memory', "#{MEMORY}"]
			end
		end
	end
	#-----------------------------------------------#
        (0..NBSTN - 1).each do |i|
                config.vm.define "bstn#{i}" do |bastion|
                        bastion.vm.hostname = "bstn#{i}"
                        bastion.vm.network :private_network,
                                ip: "#{SUBNET}.#{$last_ip_digit+=1}"


                	# virtualbox
                	bastion.vm.provider :virtualbox do |vb|
                        	vb.customize ['modifyvm', :id, '--memory', "#{MEMORY}"]
                	end

			# run the provisioner after the last machine comes up
			bastion.vm.provision 'ansible', &ansible_provision if i == (NBSTN-1)
			bastion.vm.provision 'shell', path: './bastion_config.sh'
		end
	end
end
