# Verify MJFS v1

Download only [`MJFSv1.zip`](https://github.com/MarceloAlejandroJorquera/MJFS/releases/tag/v1) from the GitHub release. The archive must contain exactly two root-level files:

```text
MJFSv1.exe
SHA256SUMS.txt
```

Extract both files to an empty directory, then run Windows PowerShell 5.1:

```powershell
$lines = @(Get-Content -LiteralPath .\SHA256SUMS.txt)
if ($lines.Count -ne 1 -or $lines[0] -cnotmatch '^[0-9a-f]{64}  MJFSv1\.exe$') {
    throw 'Checksum file is malformed'
}
$expected = $lines[0].Substring(0,64)
$actual = (Get-FileHash -LiteralPath .\MJFSv1.exe -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -cne $expected) { throw 'MJFSv1.exe SHA256 mismatch' }
Write-Host 'MJFSv1.exe SHA256 PASS'
```

Verify the extraction list as well: reject unexpected extra files, subdirectories or duplicate entries. The publication tool's `-Mode Verify` independently validates archive structure, SHA-256 and PE32+ AMD64 format.

**Note:** there is deliberately no ZIP self-hash inside the archive. A ZIP cannot include a stable SHA-256 of itself without a circular dependency. The publisher saves the ZIP SHA-256 separately in a local audit manifest but uploads only `MJFSv1.zip`.

SHA-256 checks are for corruption detection and do not independently authenticate the GitHub publisher account.
