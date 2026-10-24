# MJFS v1

**Fast native file discovery for Windows x64.** MJFS combines a compact, keyboard-friendly Win32 interface with indexed volume searching, live filesystem integration where available, and rich metadata filtering.

<p align="center">
  <img src="assets/badges/version.svg" alt="MJFS v1" />
  <img src="assets/badges/platform.svg" alt="Windows x64" />
  <img src="assets/badges/distribution.svg" alt="Portable EXE" />
  <img src="assets/badges/filetypes.svg" alt="NTFS, FAT32 and WPD/MTP" />
</p>

## Screenshots

| Search — dark | Search — inverted colors |
| :--: | :--: |
| ![MJFS dark search results, columns and status](assets/screenshots/search-dark.png) | ![MJFS light theme and selected search result](assets/screenshots/search-light.png) |

| Filter options | Volume discovery |
| :--: | :--: |
| ![MJFS Show and Hide filter options](assets/screenshots/filter-dark.png) | ![MJFS volume inventory, NTFS, FAT32 and WPD/MTP](assets/screenshots/volumes-dark.png) |

## Features

- **Indexed file search** with a native Windows x64 desktop interface and live query updates.
- **Filesystem-aware discovery:** NTFS volumes with USN-based updates where supported; FAT32 indexing through a separate discovery route; and connected WPD/MTP devices through snapshot-based enumeration.
- **Search and filter:** name/path/type, size, Created/Modified timestamps, count, wildcard patterns (`*`, `?`), match-case options and Show/Hide rules.
- **Sortable columns:** Name, Path, Type, Size, Created, Modified and Count.
- **Precise interface:** custom table, hover details, compact filter and volumes panels, dark/light inversion and refined scrollbar behavior.
- **Portable distribution:** a single `MJFSv1.exe` in a ZIP archive. No installer is needed for the executable itself.

> Behavior and indexing coverage depend on the filesystem, device permissions, host configuration and device capabilities. WPD/MTP results are snapshots, not USN-live records. Portable packaging does not imply exhaustive cross-host certification.

## Download and verify

Get the **single release asset**, [`MJFSv1.zip`](https://github.com/MarceloAlejandroJorquera/MJFS/releases/latest), from the [MJFS Releases page](https://github.com/MarceloAlejandroJorquera/MJFS/releases). Its two root-level files are:

- `MJFSv1.exe` — the portable Windows x64 application.
- `SHA256SUMS.txt` — the SHA-256 checksum of `MJFSv1.exe`.

Extract both into the same folder. On Windows PowerShell 5.1, run:

```powershell
$lines = @(Get-Content -LiteralPath .\SHA256SUMS.txt)
if ($lines.Count -ne 1 -or $lines[0] -cnotmatch '^[0-9a-f]{64}  MJFSv1\.exe$') {
    throw 'Invalid SHA256SUMS.txt'
}
$expected = $lines[0].Substring(0,64)
$actual = (Get-FileHash -LiteralPath .\MJFSv1.exe -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -cne $expected) { throw 'MJFSv1.exe SHA256 mismatch' }
.\MJFSv1.exe
```

For full archive-layout validation, see the [verification guide](docs/VERIFY.md). SHA-256 detects accidental modifications but is not, on its own, proof of publisher identity.

## Volume support

| Source | Discovery/indexing | Change model |
| --- | --- | --- |
| NTFS | Runtime-discovered volumes | USN-driven when available, with capability/permission-aware paths |
| FAT32 | Runtime-discovered accessible volumes | Filesystem enumeration and refresh |
| WPD / MTP | Supported connected Windows Portable Devices | Device snapshot / refresh |

Device access and reported metadata vary. Some fields may be unknown or unavailable until indexed.

## Build and documentation

- [Build requirements and development workflow](docs/BUILD.md)
- [Portability and limitations](docs/PORTABILITY.md)
- [Release notes](docs/RELEASE_NOTES_v1.md)
- [Release verification](docs/VERIFY.md)

The production application is built in **x64 Release** with MSVC/CMake/Ninja; the project build scripts use **Windows PowerShell 5.1**. The executable includes its required UI font resource. Documentation, build recipes and screenshots are distinct from any user-specific local indexes or caches.

## Issues

When reporting a reproducible issue, include the MJFS version, Windows version, filesystem/device category, expected and actual results, and reproduction steps. Do **not** attach private search indexes, filesystem journals, personal file listings or machine-specific diagnostic dumps.

## License and distribution

See [distribution notices](docs/DISTRIBUTION.md). No new source-code license is granted by this README.
