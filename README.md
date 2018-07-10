# Vagrant Ubuntu

## Overview

This project is an opinionated quickstart Ubuntu environment, intended to be used in *sidecar* fashion as part of other projects to provide *consistent*, *repeatable* and *abstracted* development environments.

Roughly speaking, the value of this sidecar environment is applicable to projects where the development environment needs to be abstracted from the development of the project itself.

For example, I use it alongside my Ubuntu dotfiles repository to provide a development environment for the maintenance of my Ubuntu dotfiles.
This allows me to develop and test my dotfiles across different versions of Ubuntu and hosting environments (local and cloud) without affecting my local machine dotfiles.

Another common use case is that of data science projects, where the actual development environment might need to change to reflect the requirements of the particular stage within the development pipeline. For example, moving between locally hosted Ubuntu images and GPU-backed cloud images to match processing requirements, without having to manually synchronize codebases and data between environments.

As part of the sidecar design, this project sets up guest machines to share the development environment of the host.
This is both to simplify the setup of the guest machine, as well as to allow the re-use of secrets on the host machine from the guest without having to copy them around.

## Installation

The following prerequisites are required and should be installed via your usual package manager:

- Virtualbox
- Vagrant

In addition, please run the `vagrant-setup` shell script to bring in the requisite vagrant box images and plugins.

### Host ssh keypair

The host machine requires an ssh keypair to be setup. This can either be a keypair specific to this project or re-use of an existing one.
This keypair will be used to connect to guest machines, as well as being re-used on the guest machines themselves for ssh cliet connectivity.

### SSH-agent forwarding

The vagrant guest uses ssh-agent forwarding to re-use keys on the host by setting the `forward_agent` configuration element to true.
This prevents keys having to be copied onto the guest.

For this to work, the respective private keys will need to be added to the ssh-agent on the host machine.

This is done as follow, assuming that the relevant keypair is `id_rsa`:

```sh
# From a prompt on the host machine
# Replace id_rsa with the relevant keypair name
ssh-add ~/.ssh/id_rsa

# Verify the key was added
ssh-add -L
```

### AWS credentials

In order to use AWS hosted guest machines, the host machine will need to be setup with AWS credentials.

An example of this configuration is as follows:

```sh
# ~/.aws/config
[profile vagrant]
region = eu-west-1
output = json

# ~/.aws/credentials
[vagrant]
aws_access_key_id=[AWS_ACCESS_KEY_ID]
aws_secret_access_key=[AWS_SECRET_ACCESS_KEY]
```

### Passwordless hosts file management on the host

The `vagrant-hostmanager` vagrant plugin is used to manage the host `hosts` file. As part of starting and stopping virtual machines, this plugin writes the guest hostname into the hosts `hosts` file. By default, this will require root priviledges and hence a password to be entered during `vagrant up` etc.

The updating of the `hosts` file can be allowed to run without a password entered through the use of the hosts machine `sudoers` file.

Enter the following entries using the `visudo` command:

```sh
# Cmnd alias specification
# Update [USERNAME] to your username
Cmnd_Alias CP_HOSTS = /bin/cp /Users/[USERNAME]/.vagrant.d/tmp/hosts.local /etc/hosts

# User privilede specification
%staff ALL=(root) NOPASSWD: CP_HOSTS
```

## Installation as a sidecar project

Installation of this project as a sidecar into a parent project is as follows:

1. Submodule this project into the host project

    Link this project into a top-level `vagrant` directory:

    ```sh
    git submodule add [THIS REPOS] vagrant/
    ```

2. Symlink the included Vagrantfile into the host project root directory

    ```sh
    ln -s vagrant/Vagrantfile ./Vagrantfile
    ```

3. Create the project vagrant configuration file from the included template

    ```sh
    cp vagrant/.vagrantuser.example ./.vagrantuser
    ```

4. Update the configuration file

    The paths will all need updating as per the examples.
    I like to update the `hostname` parameter to the name of the host project so I can `ssh [project]` to access the development environment.

5. Copy / merge the sidecar gitignore into place

    ```sh
    cp vagrant/.gitignore ./
    ```

6. Vagrant up and snapshot

    ```sh
    vagrant up
    vagrant snapshot save baseline
    ```

7. Keep things up-to-date

    ```sh
    git submodule foreach git pull
    ```

## Configuration

The Vagrantfile is intended to be immutable with all configuration factored into the `.vagrantuser`.
An example of this file is given in the `.vagrantuser.example` file.

Note that your `.vagrantuser` might contain secrets and is therefore excluded from git commits via the `.gitignore` file.

## Machines

The `Vagrantfile` is structured using a vagrant `machine-machine` environment.
This allows for the same guest configuration to be re-used across multiple providers and run independently of each other.
For example, it is possible to define a local Virtual box machine, as well as a cloud hosted AWS machine.
These can then be launched individually of each other, including concurrently.

From the perspective of vagrant cli usage, this requires the respective machine name to be appended to the end of all vagrant commands.

For example:

```sh
vagrant up [MACHINE_NAME] # instead of vagrant up
vagrant destroy [MACHINE_NAME] # instead of vagrant destroy
```

## Workflow

```sh
vagrant up [MACHINE_NAME] # start and provision machine
vagrant halt [MACHINE_NAME] # stop machine
vagrant up [MACHINE_NAME] # restart halted machine - note doesnt run provisioners
vagrant destroy --force [MACHINE_NAME # Destroy machine
```

### Guest machine access

Default access to the running guest is via the `vagrant ssh` command.
This connects to the guest using the `vagrant` user.
Alternatively, native ssh can be used by setting the `setup_ssh_config` to true.
This generates `ssh_config` entries for running vagrant guest instances.
These can then be accessed using `ssh [HOSTNAME]` where `HOSTNAME` is given by the `hostname` configuration element.

### VirtualBox (and other non-cloud) only

The `vagrant up` process can take several minutes to complete, especially if configured to auto-upate
the Virtualbox guest additions and OS.

In these cases, a baseline snapshot can be taken. Restoring to this snapshot will be considerably
quicker than reprovisioning via a `destroy / up` cycle.

```sh
vagrant snapshot push
vagrant snapshot pop
# or
vagrant snapshot save [NAME]
vagrant snapshot restore [NAME]
```

## Troubleshooting

Vagrant and Virtualbox can occasionally get mixed up with running instances.
A brute force method of undoing the mess is as follows:

```sh
killall -9 ruby
killall -9 vagrant
killall -9 vboxheadless

vboxmanage list vms
# Then for each id
vboxmanage unregistervm [ID] --delete
```

Then delete the corresponding VM directory under "~/VirtualBox VMs".

## Notes

### Vagrant insecure public key

Vagrant boxes come bundled with the vagrant insecure public key.
This supports the initial ssh connection through the well known key.

Vagrant will by default replace the bundled insecure key with a per-guest keypair on `vagrant up`, or if the `config.ssh.insert_key` is set to true.
Additionally, this project supports specific keypair usage via the `use_own_key` configuration element.
This prevents vagrant inserting the per-guest keypair, as well as removing the insecure public key from the guest.
