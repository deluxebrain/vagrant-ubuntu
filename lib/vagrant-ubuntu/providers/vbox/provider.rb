module VagrantUbuntu
    module Providers
        module VirtualBox

            def self.provision(vagrant, user_config, machine_name, machine_config)

                vagrant.vm.define machine_name do |config|

                    # Guest settings
                    config.vm.box = machine_config.guest.box
                    config.vm.hostname = machine_config.guest.hostname

                    # SSH configuration
                    config.ssh.port = machine_config.ssh.port
                    config.vm.network :forwarded_port,
                        guest: 22,
                        host: machine_config.ssh.port,
                        auto_correct: false,
                        id: 'ssh'

                    # Networking configuration
                    machine_config.networking.forwarding.each do |key, value|
                        config.vm.network :forwarded_port,
                            guest: value[:guest],
                            host: value[:host],
                            auto_correct: value[:auto_correct],
                            id: key
                    end

                    # Verify guest vbox additions installation
                    config.trigger.after :up do |trigger|
                        trigger.info = "INFO: Getting vbox-additions version information"
                        trigger.run_remote = {
                        inline: File.join(user_config.meta.guest_script_path, "query-vbox-additions-info")
                        }
                    end

                    # Take initial snapshot
                    config.trigger.after :up do |trigger|
                        if machine_config.snapshot.take_snapshot
                            trigger.info = "INFO: Taking initial snapshot"
                            trigger.run = {
                                path: File.join(vagrant.user.meta.host_script_path,
                                    "take-snapshot"),
                                args: [
                                    "#{machine_name}",
                                    "#{machine_config.snapshot.snapshot_name}"
                                ]
                            }
                        end
                    end

                    # Hypervisor configuration
                    config.vbguest.auto_update = user_config.common.vbox_settings.auto_update_guest_additions
                    config.vbguest.no_remote = false
                    config.vm.provider 'virtualbox' do |vbox, override|
                        vbox.name = machine_config.guest.hostname # vbox ui title
                        vbox.gui = machine_config.vbox_settings.gui
                        vbox.memory = machine_config.vbox_settings.ram
                        vbox.cpus = machine_config.vbox_settings.cpus
                    end

                    PROVIDERS[:common].provision(config,
                        user_config,
                        machine_name,
                        machine_config)
                end
            end
        end
    end
end