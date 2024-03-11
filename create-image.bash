#!/usr/bin/env bash

# Define the menu entry content
MENTRY_GSHELL="
set timeout=5

menuentry 'Small Linux (INSTALLER)' {
    set root='hd0,gpt1'
    linux /EFI/Custom/vmlinuz-sl root=/dev/sda2 console=tty0 loglevel=7 vga=normal debug
}
"

debug() {
   read -p "Press any key to continue... " c
}

usage() {
   echo "$1"
   echo -e "\t--output [PATH/TO/IMAGE.img]"
   echo -e "\t--size [size mb]"
   exit 1
}

OUTPUT="./small-linux.img"
SIZE="2048"

# Check for root
if [[ "$(id -u)" == 0 ]]; then
   echo "WARNING: You are root, you could potentially damage your system"
   read -p "Do you want to continue(y/n): " answer
   if [[ ${answer} != [yY] ]]; then
      echo "Exiting..."
      exit 0
   fi
fi

# Parse arguments
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
   current_arg="${args[i]}"

   case "${current_arg}" in
      --output)
         if [[ $((i + 1)) -lt  ${#args[@]} ]]; then
            OUTPUT="${args[i + 1]}"
            ((i++))
         else
            usage $0
         fi
         ;;
      --size)
         if [[ $((i + 1)) -lt ${#args[@]} ]]; then
            SIZE="${args[i + 1]}"
            ((i++))
         else
            usage $0
         fi
         ;;
      --help)
        usage $0
        ;;
   esac
done

echo "Variables"
echo "OUTPUT: ${OUTPUT}"
echo "SIZE: ${SIZE}"

# DD the image
dd if=/dev/zero of=${OUTPUT} bs=1M count=${SIZE}

# Create loop device
loop_device=$(sudo losetup -f --show "${OUTPUT}")

# Create gpt
sudo parted -s "${loop_device}" mklabel gpt

# Create boot partition
sudo parted -s "${loop_device}" mkpart primary fat32 2048s 1048576s
sudo parted -s "${loop_device}" set 1 boot on
sudo parted -s "${loop_device}" set 1 esp on

# Create root partition
sudo parted -s "${loop_device}" mkpart primary ext4 1048577s 100%

boot_partition="${loop_device}p1"
root_partition="${loop_device}p2"

echo "Loop Device: ${loop_device}"
echo "Boot Partition: ${boot_partition}"
echo "Root Partition: ${root_partition}"

# Format partitions
sudo mkfs.vfat ${boot_partition}
sudo mkfs.ext4 ${root_partition}

# Mount partitions
sudo mkdir -p /tmp/sl-boot
sudo mkdir -p /tmp/sl-root
sudo mount -t vfat ${boot_partition} /tmp/sl-boot
sudo mount ${root_partition} /tmp/sl-root
sudo mkdir -p /tmp/sl-boot/EFI/Custom

# Install grub
sudo grub-install --target=x86_64-efi --boot-directory=/tmp/sl-boot --efi-directory=/tmp/sl-boot --removable --recheck

# Apply configuration
echo "${MENTRY_GSHELL}" | sudo tee /tmp/sl-boot/EFI/BOOT/grub.cfg >/dev/null

debug

# Umount partitions
sudo umount ${boot_partition}

# Remove loop device
sudo losetup -d "${loop_device}"

# debug
sudo parted -s "${OUTPUT}" print
