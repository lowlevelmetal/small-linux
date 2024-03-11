#!/usr/bin/env bash

# Clone the kernel
git clone https://github.com/torvalds/linux.git && cd linux

# Configure kernel
make menuconfig

# Build the kernel
make -j$(nproc)
