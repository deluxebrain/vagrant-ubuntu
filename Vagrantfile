# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require_relative 'lib/vagrant-ubuntu/providers/common/provider'
require_relative 'lib/vagrant-ubuntu/providers/vbox/provider'

PROVIDERS = {
  :common => VagrantUbuntu::Providers::Common,
  :vbox => VagrantUbuntu::Providers::VirtualBox
}

# Load user configuration as an OpenStruct object
user_config = JSON.parse(
  YAML::load_file('.vagrantuser').to_json,
  object_class: OpenStruct)

Vagrant.configure('2') do |config|

  # Machines
  user_config.machines.marshal_dump.each do |machine_name, machine_config|
    provider = PROVIDERS[machine_config.provider.to_sym]
    provider.provision(config,
      user_config,
      machine_name,
      machine_config)
  end

  # Host hostfile management
  if user_config.host.manage_hosts
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
  end

  # SSH configuration
  config.ssh.username = user_config.ssh.username
  config.ssh.forward_agent = true

  # Keypair configuration
  if user_config.ssh.use_own_key
    config.ssh.insert_key = false
    config.ssh.private_key_path = [
      File.expand_path(user_config.ssh.private_key_path),
      File.expand_path(user_config.ssh.vagrant_insecure_key_path)
    ]

    # Write over the authorized_keys files on the guest such that:
    # - The specified private key is authorized
    # - The packaged insecure key authorization is removed
    config.vm.provision 'file',
      source: File.expand_path(user_config.ssh.public_key_path),
      destination: '~/.ssh/authorized_keys'
  else
    # Replace the bundled insecure key with a new private key
    config.ssh.insert_key = true
  end

  # Verify ssh forwarding is working
  config.vm.provision "verify_ssh_forwarding",
    type: "shell",
    inline: File.join(user_config.meta.guest_script_path,
      "guest/verify-ssh-forwarding"),
    privileged: false

  # Directory shares
  user_config.common.shares.each do |key, value|
    config.vm.synced_folder File.expand_path(value[:source]),
      value[:destination],
      type: "rsync",
      rsync__auto: true
  end

  # File copies
  user_config.common.files.marshal_dump.each do |key, value|
    config.vm.provision "file",
      source: File.expand_path(value.source),
      destination: value.destination
  end

  # Repos
  if user_config.common.respond_to?(:repos)
    if user_config.common.repos.marshal_dump.any?
      # Add github to known_hosts else git will return non-zero exit code
      script = <<-SCRIPT
      ssh-keyscan -t rsa github.com >> "${HOME}/.ssh/known_hosts" 2>/dev/null
      SCRIPT
      config.vm.provision "setup_known_hosts",
        type: "shell",
        inline: script,
        privileged: false

      user_config.common.repos.marshal_dump.each do |key, value|
        script = <<-SCRIPT
        mkdir -p "#{value.local_path}" || exit
        cd "$_" || exit
        git clone #{value.remote}
        SCRIPT
        config.vm.provision "repos",
          type: "shell",
          inline: script,
          privileged: false
      end
    end
  end

  # OS bootstrapping
  config.vm.provision "bootstrap",
    type: "shell",
    path: File.join(user_config.meta.host_script_path, "guest/bootstrap"),
    privileged: true

  # Timezone
  config.vm.provision "timezone",
    type: "shell",
    path: File.join(user_config.meta.host_script_path, "guest/setup-timezone"),
    privileged: true,
    args: [
      "#{user_config.common.guest.timezone}"
    ]

  # Desktop
  if user_config.common.install_desktop
    config.vm.provision "desktop",
      type: "shell",
      path: File.join(user_config.meta.host_script_path, "guest/setup-desktop"),
      privileged: true
  end

  # Setup dotfiles
  if user_config.common.respond_to?(:dotfiles)
    if user_config.common.dotfiles.setup_dotfiles
      config.vm.provision "dotfiles",
        type: "shell",
        inline: user_config.common.dotfiles.install_cmd,
        privileged: false
    end
  end
end