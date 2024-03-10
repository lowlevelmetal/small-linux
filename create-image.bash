#!/usr/bin/env bash

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
SIZE="4096"

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
sudo parted -s "${loop_device}" mkpart primary fat32 2048s 1073663s
sudo parted -s "${loop_device}" set 1 esp on

boot_partition="${loop_device}p1"

echo "Loop Device: ${loop_device}"
echo "Boot Partition: ${boot_partition}"

sudo mkfs.vfat ${boot_partition}

# Mount partitions
sudo mkdir -p /tmp/sl-boot
sudo mount -t vfat ${boot_partition} /tmp/sl-boot
sudo mkdir -p /tmp/sl-boot/EFI/BOOT

# Install grub
sudo grub-install --target=x86_64-efi --boot-directory=/tmp/sl-boot --efi-directory=/tmp/sl-boot --bootloader-id=grub

# Umount partitions
sudo umount ${boot_partition}

# Remove loop device
sudo losetup -d "${loop_device}"

# debug
sudo parted -s "${OUTPUT}" print
