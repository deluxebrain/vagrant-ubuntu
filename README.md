# Vagrant Ubuntu

## Intended audience

The purpose of this project is to provide an abstraction around the complexities of `vagrant`, `virtualbox` (and other hypervisors) and system scripting to allow for the creation of virtualized development environments using a single declarative configuration file.

If you know vagrant and virtualbox and your virtualization requirements are vanilla, *do not use this project* - just stick to a `Vagrantfile`.

## Project overview

This project is an opinionated quickstart Ubuntu environment, intended to be used in *sidecar* fashion as part of other projects to provide *consistent*, *repeatable* and *abstracted* development environments. Under the covers its uses `vagrant` and `virtualbox`. These are abstracted away behind a declarative configuration layer allowing some reasonably complex scenarios to be performed with very little knowledge of the underlying tooling.

Roughly speaking, the value of this sidecar environment is applicable to projects where the development environment needs to be abstracted from the development of the project itself.

For example, I use it alongside my Ubuntu dotfiles repository to provide a development environment for the maintenance of my Ubuntu dotfiles.
This allows me to develop and test my dotfiles across different versions of Ubuntu and hosting environments (local and cloud) without affecting my local machine dotfiles.

As part of the sidecar design, this project sets up the guest machines to share the development environment of the host.
This is both to simplify the setup of the guest machines, as well as to allow the re-use of secrets on the host machine from the guest without having to copy them around.

## Installation

The following prerequisites are required and should be installed via your usual package manager:

- Virtualbox
- Vagrant

In addition, please run the `./setup/vagrant-setup` shell script to bring in the requisite vagrant box images and plugins.

## Configuration

The `Vagrantfile` is intended to be immutable with all configuration factored into the `.vagrantuser` configuration file.
If you need to make changes to the Vagrantfile then either you are doing something wrong or the support for the change should be baked into the project and exposed out via the configuration file.
Note that your `.vagrantuser` might contain secrets and is therefore excluded from git commits via the `.gitignore` file.

An example of this file is given in the `.vagrantuser.example` file.

## Guest machine connectivity

### Host ssh keypair

The host machine requires an ssh keypair to be setup. This can either be a keypair specific to this project or the re-use of an existing one.

This keypair will be used to connect to guest machines, as well as being re-used on the guest machines themselves for ssh client connectivity via ssh-agent forwarding.

Note that vagrant does not support keys generated using the `Ed25519` algorithm, so stick with something like this:

```sh
ssh-keygen -a 100 -o -t rsa -b 4096 -f ~/.ssh/id_rsa
```

It is possible however to use an `rsa` key specifically for vagrant and then use your normal `Ed25519` keys via agent forwarding. This is achieved by adding the `Ed222159` key to your `ssh-agent` instead of the vagrant `rsa` key. This will then be used from the guest machine.

### Ssh-agent forwarding

The vagrant guest can be made to use `ssh-agent` forwarding to re-use keys on the host by setting the `forward_agent` configuration element to true.
This prevents keys having to be copied onto the guest.

For this to work, the respective key pair will need to be added to the `ssh-agent` on the host machine. Note that the key(s) you add to the `ssh-agent` are independent to those that you use to ssh into the guest machine. To be explicit - they do not need to be the same.

This is done as follow, assuming that the relevant keypair is `id_rsa`:

```sh
# Assumes id_rsa, replace as appropriate
ssh-add ~/.ssh/id_rsa

# Verify the key was added to the ssh-agent
ssh-add -L
```

### Passwordless hosts file management on the host

The `vagrant-hostmanager` vagrant plugin is used to manage the host `hosts` file. As part of starting and stopping virtual machines, this plugin writes the guest hostname into the hosts `hosts` file. By default, this will require root priviledges and hence a password to be entered during `vagrant up` etc.

The updating of the `hosts` file can be allowed to run without a password through the use of the hosts machine `sudoers` file.

This can be setup as follos using the `visudo` command:

```sh
# Cmnd alias specification
# Replace [USER] with your user name
Cmnd_Alias CP_HOSTS = /bin/cp /Users/[USER]/.vagrant.d/tmp/hosts.local /etc/hosts

# User privilede specification
%staff ALL=(root) NOPASSWD: CP_HOSTS
```

### Ssh connectivity to the guest machine

Default access to the running guest is via the `vagrant ssh` command. This connects to the guest using the `vagrant` user.

Alternatively, native ssh can be used by setting the `setup_ssh_config` to true. This generates `ssh_config` entries corresponding to your running vagrant guest instances.

These can then be accessed using `ssh [HOSTNAME]` where `HOSTNAME` is given by the `hostname` configuration element.

## Vagrant usage

### Multi-machines environment

The `Vagrantfile` is structured using a vagrant `multi-machine` environment. This allows for the same guest configuration to be re-used across multiple providers and run independently of each other.

For example, it is possible to define a local Virtual box machine, as well as a cloud hosted AWS machine. These can then be launched individually of each other, including concurrently.

From the perspective of vagrant cli usage, this requires the respective machine name to be appended to the end of all vagrant commands.

For example:

```sh
vagrant up [MACHINE_NAME] # instead of vagrant up
vagrant destroy [MACHINE_NAME] # instead of vagrant destroy
```

### Vagrant workflow

Example workflow usage and corresponding Vagrant cli commands:

```sh
vagrant up [MACHINE_NAME] # start and provision machine
vagrant halt [MACHINE_NAME] # stop machine
vagrant up [MACHINE_NAME] # restart halted machine - note doesnt run provisioners
vagrant destroy --force [MACHINE_NAME # Destroy machine
```

## Hypervisors

### VirtualBox

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

This can be automated using the `snapshot` configuration element.

## Appendices

### Installation as a sidecar project

Installation of this project as a sidecar into a parent project is as follows:

1. Submodule this project into the host project

    Link this project into a top-level `vagrant` directory:

    ```sh
    git submodule add git@github.com:deluxebrain/vagrant-ubuntu.git vagrant/
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

    Ensure that the following are all correct, remembering to factor in the submodule directory:
    - host_script_path
    - guest_script_path
    - host_templates_path

5. Copy / merge the sidecar gitignore into place

    ```sh
    cp vagrant/.gitignore ./
    ```

6. Keep things up-to-date

    ```sh
    git submodule foreach git pull
    ```

### Troubleshooting

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

### Vagrant insecure public key

Vagrant boxes come bundled with the vagrant insecure public key. This solves the chicken and the egg problem of making the initial ssh connection through the use of a well known key.

Vagrant will by default replace the bundled insecure key with a per-guest keypair on `vagrant up`, or if the `config.ssh.insert_key` is set to true.

Additionally, this project supports specific keypair usage via the `use_own_key` configuration element. This prevents vagrant inserting the per-guest keypair, as well as removing the insecure public key from the guest. This allows you to remain in control of how ssh keypairs are used, allowing for native ssh usage and the use of the ssh-agent for forwarding.
