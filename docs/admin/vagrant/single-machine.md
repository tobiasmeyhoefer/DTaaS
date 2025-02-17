# DTaaS on Single Vagrant Machine

These are installation instructions for running DTaaS application
inside one vagrant Virtual Machine.  The setup requires a
machine which can spare 16GB RAM, 8 vCPUs and 50GB Hard Disk
space to the vagrant box.

A dummy **foo.com** URL has been used for illustration.
Please change this to your unique website URL.

Please follow these steps to make this work in your local environment.

1. Create [**dtaas** Vagrant box](./base-box.md).
   You would have created an SSH key pair - _vagrant_ and
   _vagrant.pub_ for the vagrant box.
   The _vagrant_ is the private SSH key; Copy _vagrant_ SSH private key into
   the current directory (`deploy/vagrant/single-machine`).
   This shall be useful for logging into the vagrant
   machine created for single-machine deployment.
1. Update the **Vagrantfile**. Fields to update are:
    1. Hostname (`node.vm.hostname = "foo.com"`)
    1. MAC address (`:mac => "xxxxxxxx"`).
    This change is required if you have a DHCP server assigning domain names
    based on MAC address. Otherwise, you can leave this field unchanged.
    1. Other adjustments are optional.
1. Execute the following commands from terminal

```bash
vagrant up
vagrant ssh
```

Set a cronjob inside the vagrant virtual
machine to remote the conflicting default route.

```bash
wget https://raw.githubusercontent.com/INTO-CPS-Association/DTaaS/feature/distributed-demo/deploy/vagrant/route.sh
sudo bash route.sh
```

If you only want to test the application and
are not setting up a production instance, you can
follow the instructions of [single script install](../trial.md).

If you are not in a hurry and would rather have a production
instance, follow the instructions of [regular server installation](../host.md)
setup to complete the installation.
