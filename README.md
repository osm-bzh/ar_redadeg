# ansible-redadeg

An Ansible project to configure reproducible VMs for the Redadeg (https://ar-redadeg.bzh)

To build and launch a VM:

```
$ make run_vm
```

To launch the playbook (after having installed and created the first user the VM):

```
$ uv run ansible-playbook --ask-vault-pass
```
