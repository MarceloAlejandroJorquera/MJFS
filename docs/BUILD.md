# Building MJFS v1.1

## Requirements

Windows x64, Visual Studio Build Tools (MSVC x64 and Windows SDK), CMake and Ninja on PATH, Windows PowerShell 5.1, and the complete authorized private project checkout including embedded resource inputs.

## Qualified Release build

Run from the private `MJFS\v1.1` project root:

```powershell
.\MJFS-P9NZ.cmd Verify
.\MJFS-P9NZ.cmd SelfTest
.\MJFS-P9NZ.cmd BuildTests
.\MJFS-P9NZ.cmd BuildRelease
```

The output is `dist\MJFSv1.1.exe`. The broker is compiled privately to `out\build-release\broker-payload\MJFSv1.1Broker.exe`, embedded as `RT_RCDATA 102` and compared byte-for-byte with the resource in the GUI. The installed service image remains under protected ProgramData storage, and is not a separate distribution asset.

## Release ZIP and publication

The version-specific release command `MJFS-V11-RELEASE.cmd` validates the native resource identity test and creates `dist\MJFSv1.1.zip` with exactly `MJFSv1.1.exe` and `SHA256SUMS.txt`. `VerifyZip` recomputes checksums from the actual ZIP member bytes. It records the ZIP's own checksum locally under `out\release-v11`.

Only the public documentation is pushed to `main`. Upload **one** asset, `MJFSv1.1.zip`, manually on the [v1.1 GitHub release](https://github.com/MarceloAlejandroJorquera/MJFS/releases/tag/v1.1). Neither the broker intermediate nor tests, logs, local indexes, service image, or source patch archives should be uploaded.
