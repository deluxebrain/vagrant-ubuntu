# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require_relative 'lib/vagrant-ubuntu/providers/common/provider'
require_relative 'lib/vagrant-ubuntu/providers/vbox/provider'
#require_relative 'lib/vagrant-ubuntu/providers/aws/provider'

user_config = YAML.load_file('.vagrantuser')

PROVIDERS = {
  :common => VagrantUbuntu::Providers::Common,
  :vbox => VagrantUbuntu::Providers::VirtualBox,
  #:aws => VagrantUbuntu::Providers::Aws
}

Vagrant.configure('2') do |config|

  # Machines
  config.user.machines.each do |machine_name, machine_config|
    provider = PROVIDERS[machine_config.provider]
    provider.provision(config,
      machine_name,
      machine_config)
  end

  # Host hostfile management
  if config.user.host.manage_hosts
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
  end

  # SSH configuration
  config.ssh.username = config.user.ssh.username
  config.ssh.forward_agent = true

  # Keypair configuration
  if config.user.ssh.use_own_key
    config.ssh.insert_key = false
    config.ssh.private_key_path = [
      File.expand_path(config.user.ssh.private_key_path),
      File.expand_path(config.user.ssh.vagrant_insecure_key_path)
    ]

    # Write over the authorized_keys files on the guest such that:
    # - The specified private key is authorized
    # - The packaged insecure key authorization is removed
    config.vm.provision 'file',
      source: File.expand_path(config.user.ssh.public_key_path),
      destination: '~/.ssh/authorized_keys'
  else
    # Replace the bundled insecure key with a new private key
    config.ssh.insert_key = true
  end

  # Verify ssh forwarding is working
  config.vm.provision "verify_ssh_forwarding",
    type: "shell",
    inline: File.join(config.user.meta.guest_script_path,
      "verify-ssh-forwarding"),
    privileged: false

  # Directory shares
  config.user.common.shares.each do |key, value|
    config.vm.synced_folder File.expand_path(value[:source]),
      value[:destination],
      type: "rsync",
      rsync__auto: true
  end

  # File copies
  config.user.common.files.each do |key, value|
    config.vm.provision "file",
      source: File.expand_path(value[:source]),
      destination: value[:destination]
  end

  # Repos
  if config.user.common.key?("repos")
    if config.user.common.repos.any?
      # Add github to known_hosts else git will return non-zero exit code
      script = <<-SCRIPT
      ssh-keyscan -t rsa github.com >> "${HOME}/.ssh/known_hosts" 2>/dev/null
      SCRIPT
      config.vm.provision "setup_known_hosts",
        type: "shell",
        inline: script,
        privileged: false

      config.user.common.repos.each do |key, value|
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
    path: File.join(config.user.meta.host_script_path, "bootstrap"),
    privileged: true

  # Timezone
  config.vm.provision "timezone",
    type: "shell",
    path: File.join(config.user.meta.host_script_path, "setup-timezone"),
    privileged: true,
    args: [
      "#{config.user.common.guest.timezone}"
    ]

  # Desktop
  if config.user.common.install_desktop
    config.vm.provision "desktop",
      type: "shell",
      path: File.join(config.user.meta.host_script_path, "setup-desktop"),
      privileged: true
  end

  # Setup dotfiles
  if config.user.common.key?("dotfiles")
    if config.user.common.dotfiles.setup_dotfiles
      config.vm.provision "dotfiles",
        type: "shell",
        inline: config.user.common.dotfiles.install_cmd,
        privileged: false
    end
  end
end