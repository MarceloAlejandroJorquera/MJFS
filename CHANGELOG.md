# Changelog

## v1.1 — 2026-10-24 — portable release and service integration

- Packaged the Windows x64 application as a single user-facing EXE in a ZIP with its SHA-256 manifest.
- Kept the broker compiler output private and embedded its exact PE bytes as a GUI resource.
- Separated Windows SCM service deployment into secured ProgramData storage.
- Refined Created/Modified timestamp presentation, including dimmed leading zeroes and a red time/date separator.
- Improved custom-drawn scrollbar backgrounds and scroll-corner border alignment during resizing.
- Retained search, filter, sorting, live-indexing and tray workflows from the v1 development line.

## v1 — initial public application release

- Native Windows x64 file-search interface with indexed results, table sorting, filters and metadata columns.
- NTFS/USN-aware indexing, FAT32 scanning and WPD/MTP device snapshot integration.
- Volume inventory, configurable filtering and theme inversion.

See [v1.1 release notes](docs/RELEASE_NOTES_v1.1.md).
