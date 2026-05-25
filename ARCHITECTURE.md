# ImmortalWrt-XG-040G-MD Architecture

This document describes the architecture of the ImmortalWrt firmware for the NOKIA BELL XG-040G-MD router.

## System Overview

The project provides OpenWrt firmware specifically tailored for the XG-040G-MD router featuring:
- **SoC**: Airoha AN7581 (64-bit ARMv8)
- **Kernel**: Linux 6.12
- **Key Features**: NPU acceleration, 10G networking, WiFi 6E support

## Core Components

### 1. Hardware Abstraction Layer
- **Target Configuration**: `config/xg-040g-md.config`
- **Device Tree**: DTS files in `target/linux/airoha/dts/`
- **Bootloader Support**: U-Boot environment tools
- **Hardware Drivers**:
  - PHY drivers (`kmod-phy-airoha-en8811h`)
  - I2C controller (`kmod-i2c-an7581`)
  - USB3 controllers (`kmod-usb3`, `kmod-usb-xhci-mtk`)

### 2. System Packages
- **Base System**: Busybox, procd, netifd, UCI configuration
- **Network Stack**: Full IPv6 support, nftables firewall
- **Storage**: ext4/vfat/exFAT filesystem support
- **Package Manager**: apk with mbedtls and keyring support

### 3. Management Interface
- **LuCI Web UI**: Chinese language support
- **SSH Server**: Dropbear with modern crypto
- **mDNS**: Local network discovery
- **Web Tools**: curl, wget-ssl, fwtool

### 4. Airoha NPU Management
- **luci-app-airoha-npu**: Main management package
  - Real-time monitoring dashboard
  - CPU frequency scaling controls
  - NPU offload management
  - Frame Engine visualization
  - PPE flow table inspection

#### NPU Application Structure
```
luci-app-airoha-npu/
├── Makefile
├── htdocs/luci-static/resources/view/airoha_npu/status.js
│   └── Real-time monitoring frontend
├── root/usr/libexec/rpcd/luci.airoha_npu
│   └── RPC backend for system calls
├── root/usr/share/luci/menu.d/luci-app-airoha-npu.json
│   └── LuCI menu integration
└── root/usr/share/rpcd/acl.d/luci-app-airoha-npu.json
    └── Permission definitions
```

### 5. Patch System
Three patch directories provide version-specific modifications:

- **patch-master**: Latest development patches
- **patch-25.12**: Stable OpenWrt 25.12 patches
- **patch-25.12.0-rc2**: Release candidate patches

Each contains:
- Kernel patches (`patches-6.12/`)
- Target-specific configurations
- Package modifications

### 6. Build Configuration
- **Target Definition**: `target/linux/airoha/an7581/target.mk`
- **Kernel Config**: `target/linux/airoha/an7581/config-6.12`
- **Device Config**: `config/xg-040g-md.config`

## Key Features Enabled

### Networking
- ✅ IPv4/IPv6 dual-stack
- ✅ PPPoE support
- ✅ Hardware offload (NPU, VLAN, PPPoE)
- ✅ 10G USXGMII interfaces
- ✅ WiFi 6E (6 GHz band support)

### Storage & Filesystems
- ✅ ext4, vfat, exFAT support
- ✅ USB storage with UAS support
- ✅ MTD/UBI flash management
- ✅ extroot (root on external storage)

### Security
- ✅ SSH with Ed25519/Curve25519
- ✅ Certificate bundle support
- ✅ Firewall4 (nftables)

### Development
- ✅ Build tools (ccache, devel packages)
- ✅ Overclocking capabilities
- ✅ Debug utilities (devmem, etc.)

## Component Relationships

The system follows OpenWrt's modular architecture where:
1. **Base System** provides core OS functionality
2. **Hardware Drivers** enable SoC-specific features
3. **Network Stack** handles routing and switching
4. **Management Interfaces** provide user access
5. **NPU Management** optimizes performance for AI/ML workloads

The luci-app-airoha-npu package sits at the intersection of hardware monitoring and user control, providing real-time visibility into the specialized processing units while allowing configuration changes for optimal performance.