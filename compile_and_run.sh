# VARIABLES
iso_dir=iso
boot_dir=boot
iso_name=kernel.iso
boot_image=boot
FLAGS="-std=c17 -Wall -Werror -pedantic -Wextra -nostdlib -ffreestanding"

# COMMANDS
gcc $FLAGS kernel.c -o kernel &&\
mkdir -p $iso_dir/$boot_dir &&\
nasm -f bin "boot.asm" -o "$iso_dir/$boot_dir/$boot_image" &&\
nasm -f bin "main.asm" -o "$iso_dir/main" &&\
genisoimage -b $boot_dir/$boot_image -no-emul-boot -boot-load-size 4 -o $iso_name $iso_dir &&\

#qemu-system-i386 -cdrom $iso_name $1 $2
qemu-system-x86_64 -cdrom $iso_name $1 $2
#virtualbox --startvm test

# -no-emul-boot   -> we use a cd, we do not want to emulate a floppy disk
# -boot-load-size -> if no-emul, we must specify the num of virtual sectors
#                    that we want to load
