UBUNTU_ISO := ubuntu-24.04.1-live-server-amd64.iso
UBUNTU_DISK := ubuntu.qcow2

.PHONY: run_vm

run_vm: $(UBUNTU_DISK)
	qemu-system-x86_64 -drive file=./ubuntu.qcow2,format=qcow2 -m 8G -cpu host -smp sockets=1,cores=2,threads=2 -enable-kvm -nic user,hostfwd=tcp::8822-:22,hostfwd=tcp::8880-:80


$(UBUNTU_ISO):
	wget https://mirrors.ircam.fr/pub/ubuntu/releases/24.04.1/ubuntu-24.04.1-live-server-amd64.iso ./

$(UBUNTU_DISK): $(UBUNTU_ISO)
	qemu-img create -f qcow2 ./$@ 100G
	qemu-system-x86_64 -cdrom ./$(UBUNTU_ISO) -boot menu=on -drive file=./$@,format=qcow2 -m 8G -cpu host -smp sockets=1,cores=2,threads=2 --enable-kvm
