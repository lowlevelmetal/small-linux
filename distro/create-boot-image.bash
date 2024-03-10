#!/usr/bin/env bash

usage() {
   echo "$1"
   echo -e "\t--output [PATH/TO/IMAGE.img]"
   echo -e "\t--size [size mb]"
   exit 1
}

OUTPUT="./boot.img"
SIZE="512"

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

# Create boot partition
mkfs.fat -F 32 ${OUTPUT}