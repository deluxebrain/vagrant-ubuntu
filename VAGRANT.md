# Vagrant 101

## Configuration

### Environment variables

- VAGRANT_HOME:

    Location of global state including box files.
    Defaults to ~/.vagrant.d.

## Boxes

Boxes are stored in ~/.vagrant.d/boxes unless overridden by the VAGRANT_HOME environment variable.

### Global box administration

The following can be run from anywhere and affect Vagrant globally:

- vagrant box list
- vagrant box add [NAME]
- vagrant box remove [NAME]
- vagrant box prune # remove old versions of installed boxes

### Local box administration

The following are run from within a Vagrant environment:

- vagrant box outdated
- vagrant box update

## Workflow

Note that in multi-machine setups each command will need to be postfixed with the machine name.

```sh
# Validate Vagrantfile
vagrant validate

# Create and configure guest machine
vagrant up

# Ssh into running Vagrant machine as the vagrant user
vagrant ssh

# Used to run in any changes to the Vagrantfile:
# Equivalent to halt followed by up
vagrant reload

# Shut down running guest
# Bring back up with vagrant up:
vagrant halt [--force]

# Shutdown and destroy running guest
vagrant destroy [--force]
```

## Provisioning

```sh
# Re-run all provisioners
vagrant provision

# Run specific provisioner
vagrant provision --provision-with [provisioner]
```

## Snapshots

```sh
# Push snapshot onto the stack
vagrant snapshot push
vagrant snapshot save [NAME]

# Pop snapshot
vagrant snapshot pop --[no-]provision, --no-delete
vagrant snapshot restore [NAME] --[no-]provision

# Snapshot management
vagrant snapshot delete [NAME]
vagrant snapshot list
```

## Vagrant introspection

```sh
# Show status of current environment
vagrant status

# List all active Vagrant environments
vagrant global-status
```