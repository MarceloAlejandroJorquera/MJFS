# Portability and filesystem behavior

MJFS v1 is targeted at x64 Windows and uses runtime discovery of accessible storage. Volumes, device identities, catalog paths and USN cursors are not intended to be tied to the development host.

- **NTFS:** journal-based changes require sufficient privileges and volume support; runtime capability/permission checks and appropriate fallback behavior are essential.
- **FAT32:** volume scans and refresh behavior differ from NTFS/USN processing.
- **WPD/MTP:** device contents are enumerated through Windows portable-device and Shell interfaces and may be dependent on user approval/unlock, connection state and device metadata. No filesystem-letter assumption should be made.
- **CPU:** any AVX2-specific code must be gated at runtime; non-AVX2 x64 hosts require a safe baseline code path.
- **Performance:** indexing and sort performance depend on the volume and host, and should not be represented by a single-machine benchmark.

Actual operating-system compatibility, first-run permissions and heterogeneous-device behavior should be regression-tested on multiple machines before making broad portability guarantees.
