# ansible-redadeg

An Ansible project to configure reproducible VMs for the Redadeg (https://ar-redadeg.bzh)

To build and launch a VM:

```
$ make run_vm
```

First, create users and groups:

```
$ uv run ansible-playbook users.yaml --extra-vars "ansible_user=user_in_vm ansible_ssh_private_key_file=ssh_key_for_vm" -K --ask-vault-pass
```

And then, launch the main playbook:

```
$ uv run ansible-playbook setup.yaml --ask-vault-pass
```
