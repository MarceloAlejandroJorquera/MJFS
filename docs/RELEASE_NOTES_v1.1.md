# MJFS v1.1 — release notes

## Distribution

- One portable Windows x64 GUI executable, `MJFSv1.1.exe`.
- One manual GitHub release asset, `MJFSv1.1.zip`, containing the GUI and its `SHA256SUMS.txt` manifest.
- The broker built by MSVC is an internal resource input (`RT_RCDATA 102`), not an additional distributable EXE.
- Windows service management uses an executable installed into protected ProgramData storage rather than the distribution directory.

## Application and interface

Retains indexed search, volume discovery, metadata filtering, file sorting and the custom-rendered Windows interface from the MJFS development line. v1.1 incorporates refinements to scrollbar geometry and repaint behavior, the scrollbar intersection border, and Created/Modified timestamps (leading-zero dimming and a red time/date separator). The project retains tray lifecycle handling and updated service integration.

## Scope and qualification

Native build verification and byte-for-byte embedded broker checks are required before staging the release. Hardware, filesystem and device behavior still require independent cross-host validation. The only approved release ZIP layout contains two root files, the EXE and its checksum manifest.

## Release asset integrity

- `MJFSv1.1.zip` SHA-256: `8f3738026a87d9afe65d5eef18385000b14c7b4ecafc5a44fbf51625d40bc446` 
- `MJFSv1.1.exe` SHA-256: `01c2aa141f6f1faaa021de5a2738f474d06f8b5575d9672ea05fae6a7eb6f869` 

The ZIP is attached manually after the draft release page is generated. It is not uploaded by Git or GitHub Actions.
