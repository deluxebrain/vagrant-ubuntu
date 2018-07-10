# Vagrant 101

## Configuration

### Environment varialbes

VAGRANT_HOME:
Location of global state including box files.
Defaults to ~/.vagrant.d.

## Boxes

Boxes are stored in ~/.vagrant.d/boxes unless overridden by the VAGRANT_HOME environment variable.

### Global box administration

The following can be run from anywhere and affect Vagrant globally:

- vagrant box list
- vagrant box add [NAME]
- vagrant box remove [NAME]

### Local box administration

The following are run from within a Vagrant environment:

- vagrant box outdated
- vagrant box update

## Workflow

Validate Vagrantfile:
vagrant validate

Create and configure guest machine:
vagrant up

SSH into running Vagrant machine as the vagrant user:
vagrant ssh

Equivalent to halt followed by up. Used to run in any changes to the Vagrantfile:
vagrant reload

Shut down running guest. Bring back up with vagrant up:
vagrant halt [--force]

Shutdown and destroy running guest:
vagrant destroy # --force

## Provisioning

Re-run all provisioners:
vagrant provision

Run specific provisioner:
vagrant provision --provision-with [provisioner]

## Snapshots

Push snapshot onto the stack:
vagrant snapshot push
vagrant snapshot save [NAME]

Pop snapshot:
vagrant snapshot pop --[no-]provision, --no-delete
vagrant snapshot restore [NAME] --[no-]provision

Management:
vagrant snapshot delete [NAME]
vagrant snapshot list

## Vagrant introspection

Show status of current environment:
vagrant status

List all active Vagrant environments:
vagrant global-status
