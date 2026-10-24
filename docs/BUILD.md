# Building MJFS v1

## Requirements

- Windows x64, Visual Studio Build Tools with MSVC C++ x64 compiler and Windows SDK.
- CMake and Ninja on PATH.
- Windows PowerShell **5.1** for build and release scripts.
- A complete, authorized private source checkout, including Win32 resources and the embedded UI font.

## Build

In the production checkout:

```powershell
.\MJFS-PORTABLE-P9NP.cmd Verify
.\MJFS-PORTABLE-P9NP.cmd BuildTests
.\MJFS-PORTABLE-P9NP.cmd BuildRelease
```

The canonical production command is `BUILD-RELEASE.cmd`. Expected output is `dist\MJFSv1.exe`.

**Do not publish** patch ZIPs, synthetic test executables or a previously built binary in place of a verified current Release build.

## GitHub publication

Repository: <https://github.com/MarceloAlejandroJorquera/MJFS>

The repository's publisher is `PUBLISH-MJFSv1.cmd`, backed by `tools/publish/Publish-MJFSv1.ps1`. Packaging produces one release asset, `MJFSv1.zip`, holding `MJFSv1.exe` and `SHA256SUMS.txt`. The archive hash and build metadata are kept in a **local-only** `RELEASE-MANIFEST.json` and are not uploaded as separate assets.

See `PUBLICATION-GUIDE.md` in the downloadable publication kit for initial clone, staging and release commands.
