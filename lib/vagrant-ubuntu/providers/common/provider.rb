module VagrantUbuntu
    module Providers
        module Common

            def self.provision(vagrant, user_config, machine_name, machine_config)

                vagrant.trigger.after :up do |trigger|
                    if user_config.host.setup_ssh_config
                        trigger.info = "INFO: Setting up ssh-config"
                        trigger.run = {
                            path: File.join(user_config.meta.host_script_path,
                                "host/setup-ssh-config"),
                            args: [
                                "#{machine_name}",
                                "#{machine_config.guest.hostname}",
                                "#{File.expand_path(user_config.host.ssh_config_path)}",
                                "#{File.expand_path(user_config.host.ssh_config_include_path)}"
                            ]
                        }
                    end
                end

                vagrant.trigger.after :up do |trigger|
                    trigger.info = "INFO: Starting rsync-auto"
                    trigger.run = {
                        path: File.join(user_config.meta.host_script_path,
                            "host/start-rsync-auto"),
                        args: [
                            "#{machine_name}"
                        ]
                    }
                end

                vagrant.trigger.after :halt do |trigger|
                    trigger.info = "INFO: Stopping rsync-auto"
                    trigger.run = {
                        path: File.join(user_config.meta.host_script_path,
                            "host/stop-rsync-auto"),
                        args: [
                            "#{machine_name}"
                        ]
                    }
                end
            end
        end
    end
end