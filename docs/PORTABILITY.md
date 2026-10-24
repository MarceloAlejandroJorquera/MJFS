# MJFS v1.1 portability and filesystem behavior

MJFS v1.1 targets supported x64 Windows hosts and discovers accessible volumes and devices at runtime. Do not assume a particular drive letter, volume serial, USN cursor, machine path, CPU instruction extension or device configuration.

- **NTFS:** USN updates require volume support and appropriate permissions. The application must check capabilities and handle denial/unavailable journal paths safely.
- **FAT32:** enumeration and refresh are distinct from NTFS journal processing.
- **WPD/MTP:** enumeration is device- and permission-dependent, and results are snapshots rather than USN-live records.
- **CPU:** hardware-specific accelerated paths require runtime detection and a safe x64 baseline fallback.
- **Service:** the single distributed GUI EXE embeds a service broker payload. Explicit service management installs the separate running image into protected ProgramData storage, subject to privileges and Windows SCM rules.
- **Performance:** throughput, indexing, and sorting vary with host and storage conditions. One-machine benchmarks are not cross-host certification.

Before broad portability claims, test on independent Windows hosts with differing filesystem layouts, storage speeds, permissions, and CPU capabilities.
