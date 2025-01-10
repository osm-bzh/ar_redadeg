# ansible-redadeg

An Ansible project to configure reproducible VMs for the Redadeg (https://www.ar-redadeg.bzh)


## Setup
We use a Makefile and `uv` to install the dependencies (few of them).
After having cloned this repository and `cd`ed into it, you can run the following command to create a `venv` and install the dependencies.

```bash
make update-deps
```

Don't forget to `source .venv/bin/activate` to be able to run the installed binaries.
You can also play with [direnv](https://direnv.net), and have a `.envrc` file in the directory like so:
```
source .venv/bin/activate
```

Thanks to this little tool, each time you'll enter the directory it will source the `venv` file. ✨

## Running the playbooks

First, create users and groups:

```bash
$ ansible-playbook users.yaml --extra-vars "ansible_user=user_in_vm ansible_ssh_private_key_file=ssh_key_for_vm" -K --ask-vault-pass
```

And then, launch the main playbook:

```bash
$ ansible-playbook setup.yaml --ask-vault-pass --extra-vars '{"drop_db":true,"update_cities":true,"update_osm":true, "osm_drop_db":true, "osm_update_db": true, "osm_clean_dumps": true}'
```

The `--extra-vars` parameter allows to force recreating the databases and download/update OSM data. They can be removed after the first run.

## Local testing
You will need [`qemu`](https://www.qemu.org/) to run a local VM.

To build and launch a VM and do local testing, run :

```bash
$ make run_vm
```

This will download an Ubuntu server .iso file, create an image for the VM. You'll need to configure a first user (eg. `user:user`).
At the end of the install process, you can enter a Github account, and your public keys will be added to the `.ssh/authorized_keys`.

Then, you can run :

```bash
$ ansible-playbook users.yaml --extra-vars "ansible_user=user ansible_ssh_private_key_file=ssh_key_for_vm_(for_github)" -K --ask-vault-pass
```
