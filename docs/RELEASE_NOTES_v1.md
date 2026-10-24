# MJFS v1 — Release notes

Native Windows x64 file search with seven sortable columns, search/Show/Hide filters and filesystem-aware indexing.

## Features

- NTFS indexing with USN-based updates where supported and permitted.
- FAT32 enumeration and refresh.
- Windows Portable Devices (WPD/MTP) discovery, snapshot indexing and refresh.
- Name, Path, Type, Size, Created, Modified and Count columns.
- Search and filter wildcard highlighting, timestamp dimming, compact panels and dark/light UI.
- Row-aligned table resizing, scrollbars and border refinements.

## Download

**One asset:** `MJFSv1.zip`, containing exactly:

```text
MJFSv1.exe
SHA256SUMS.txt
```

Extract both, verify `MJFSv1.exe` against the included SHA256SUMS.txt, then run the EXE. No installer is needed. Full verification instructions are in `docs/VERIFY.md`.

## Compatibility and limitations

- Windows x64 native build. Windows version, privilege and hardware compatibility should be checked on the target system.
- NTFS USN updates depend on permissions and volume support; no guarantee of identical behavior on every volume.
- WPD/MTP snapshots may omit metadata the device does not provide.
- Indexing throughput depends on storage and system capabilities.
- This build pipeline does not assert code signing or completed multi-host certification.
