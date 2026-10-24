# Verify MJFS v1.1

Get `MJFSv1.1.zip` from the official [v1.1 release](https://github.com/MarceloAlejandroJorquera/MJFS/releases/tag/v1.1). It must contain exactly these two root-level files, without directories, extra members, or duplicate names:

```text
MJFSv1.1.exe
SHA256SUMS.txt
```

After extracting to an empty directory, run Windows PowerShell 5.1:

```powershell
$lines = @(Get-Content -LiteralPath .\SHA256SUMS.txt)
if ($lines.Count -ne 1 -or $lines[0] -cnotmatch '^[0-9a-f]{64}  MJFSv1\.1\.exe$') {
    throw 'Invalid checksum manifest'
}
$expected = $lines[0].Substring(0,64)
$actual = (Get-FileHash -LiteralPath .\MJFSv1.1.exe -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -cne $expected) { throw 'EXE SHA256 mismatch' }
Write-Host 'MJFSv1.1.exe SHA256 PASS'
```

For the complete archive-member check, the private release tool's `VerifyZip` mode opens the actual ZIP, rejects extra entries and validates the embedded manifest against the embedded EXE. The binary also must be PE32+ AMD64 and its embedded broker resource must match the private build-time intermediate.

The ZIP cannot contain its own cryptographic hash without a circular dependency. The local release audit saves the archive SHA-256 separately; it is not a second published GitHub release asset. SHA-256 detects modification but does not, by itself, authenticate the publisher.
