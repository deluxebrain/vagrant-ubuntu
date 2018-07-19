module VagrantUbuntu
    module Providers
        module Common

            def self.provision(vagrant, machine_name, machine_config)

                # Setup host ssh config
                vagrant.trigger.after :up do |trigger|
                    if vagrant.user.host.setup_ssh_config
                        trigger.info = "INFO: Setting up ssh-config"
                        trigger.run = {
                            path: File.join(vagrant.user.meta.host_script_path,
                                "setup-ssh-config"),
                            args: [
                                "#{machine_name}",
                                "#{machine_config.guest.hostname}",
                                "#{File.expand_path(vagrant.user.host.ssh_config_path)}",
                                "#{File.expand_path(vagrant.user.host.ssh_config_include_path)}"
                            ]
                        }
                    end
                end

                vagrant.trigger.after :up do |trigger|
                    trigger.info = "INFO: Starting rsync-auto"
                    trigger.run = {
                        path: File.join(vagrant.user.meta.host_script_path,
                            "start-rsync-auto"),
                        args: [
                            "#{machine_name}"
                        ]
                    }
                end

                vagrant.trigger.after :halt do |trigger|
                    trigger.info = "INFO: Stopping rsync-auto"
                    trigger.run = {
                        path: File.join(vagrant.user.meta.host_script_path,
                            "stop-rsync-auto"),
                        args: [
                            "#{machine_name}"
                        ]
                    }
                end
            end
        end
    end
end