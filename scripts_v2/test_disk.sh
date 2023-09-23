# test disk performance

##########################################################
##***[Adjust bs and count as per your needs and setup]**##
##########################################################
dd if=/dev/zero of=/tmp/test1.img bs=1G count=1 oflag=dsync
dd if=/dev/zero of=/tmp/test2.img bs=64M count=1 oflag=dsync
dd if=/dev/zero of=/tmp/test3.img bs=1M count=256 conv=fdatasync
dd if=/dev/zero of=/tmp/test4.img bs=8k count=10k
dd if=/dev/zero of=/tmp/test4.img bs=512 count=1000 oflag=dsync


