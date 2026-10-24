[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Stage','Package','Verify','Push','Publish')]
    [string] $Mode,
    [string] $SourceRepo,
    [string] $PublicRepo,
    [string] $OutputDirectory,
    [switch] $SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$KitRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$ExpectedRepository = 'MarceloAlejandroJorquera/MJFS'
$ExpectedCloneURL = 'https://github.com/MarceloAlejandroJorquera/MJFS.git'
$ExpectedBranch = 'main'
$ReleaseTag = 'v1'
$DocumentationFiles = @(
    '.gitignore',
    'README.md',
    'CHANGELOG.md',
    'PUBLISH-MJFSv1.cmd',
    'tools/publish/Publish-MJFSv1.ps1',
    'docs/BUILD.md',
    'docs/VERIFY.md',
    'docs/PORTABILITY.md',
    'docs/DISTRIBUTION.md',
    'docs/RELEASE_NOTES_v1.md',
    'assets/badges/version.svg',
    'assets/badges/platform.svg',
    'assets/badges/distribution.svg',
    'assets/badges/filetypes.svg',
    'assets/screenshots/search-dark.png',
    'assets/screenshots/search-light.png',
    'assets/screenshots/filter-dark.png',
    'assets/screenshots/volumes-dark.png',
    '.github/ISSUE_TEMPLATE/bug_report.yml',
    '.github/ISSUE_TEMPLATE/feature_request.yml',
    '.github/SECURITY.md'
)

function Require-File([string] $Path, [string] $Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ('Missing ' + $Description + ': ' + $Path)
    }
}
function Require-Directory([string] $Path, [string] $Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw ('Missing ' + $Description + ': ' + $Path)
    }
}
function Require-Git {
    if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'git.exe not found on PATH.' }
}
function Assert-SeparateCheckouts([string] $Repo) {
    if ([string]::IsNullOrWhiteSpace($SourceRepo)) { return }
    $publicPath = [IO.Path]::GetFullPath($Repo).TrimEnd('\','/')
    $privatePath = [IO.Path]::GetFullPath($SourceRepo).TrimEnd('\','/')
    if (($publicPath -eq $privatePath) -or
        $publicPath.StartsWith($privatePath + '\', [StringComparison]::OrdinalIgnoreCase) -or
        $privatePath.StartsWith($publicPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Public checkout and private source tree must not contain one another.'
    }
}
function Assert-PublicRemote([string] $Repo) {
    Require-Git
    $remote = (& git.exe -C $Repo remote get-url origin | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Public checkout has no origin remote.' }
    $allowed = @(
        'https://github.com/MarceloAlejandroJorquera/MJFS',
        'git@github.com:MarceloAlejandroJorquera/MJFS',
        'ssh://git@github.com/MarceloAlejandroJorquera/MJFS'
    )
    $normalized = [regex]::Replace($remote, '(?i)\.git$', '')
    if ($allowed -notcontains $normalized) {
        throw ('Refusing unexpected origin URL: ' + $remote + '; expected ' + $ExpectedCloneURL)
    }
}
function Ensure-PublicCheckout {
    if ([string]::IsNullOrWhiteSpace($PublicRepo)) { throw 'Supply -PublicRepo for the separate public GitHub checkout.' }
    $repo = [IO.Path]::GetFullPath($PublicRepo)
    Assert-SeparateCheckouts $repo
    Require-Git
    $gitPath = Join-Path $repo '.git'
    if (-not (Test-Path -LiteralPath $gitPath)) {
        if (Test-Path -LiteralPath $repo) {
            $contents = @(Get-ChildItem -LiteralPath $repo -Force)
            if ($contents.Count -gt 0) { throw ('Public checkout path exists but is not an empty directory: ' + $repo) }
        }
        $parent = Split-Path -Parent $repo
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Write-Host ('[MJFS PUBLISH] Cloning empty/public repository: ' + $ExpectedCloneURL)
        # Git prints an advisory on stderr when cloning an empty repository.
        # Windows PowerShell 5.1 must not treat that advisory as a fatal script error.
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & git.exe clone $ExpectedCloneURL $repo
            $gitResult = $LASTEXITCODE
        } finally { $ErrorActionPreference = $savedPreference }
        if ($gitResult -ne 0) { throw 'Git clone failed; nothing was published.' }
    }
    Require-Directory $repo 'public checkout'
    if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) { throw 'Public checkout is not a Git repository.' }
    Assert-PublicRemote $repo
    # Empty repositories have no commits yet. Explicitly establish their unborn main branch.
    $commits = @(& git.exe -C $repo rev-list --all --max-count=1)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect Git commit history.' }
    if ($commits.Count -eq 0) {
        & git.exe -C $repo symbolic-ref HEAD ('refs/heads/' + $ExpectedBranch)
        if ($LASTEXITCODE -ne 0) { throw 'Could not establish main as the initial branch.' }
    }
    $branch = (& git.exe -C $repo symbolic-ref --quiet --short HEAD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne $ExpectedBranch) {
        throw ('Expected public branch main; found ' + $branch + '. Switch branches explicitly before publishing.')
    }
    return $repo
}
function Resolve-OutputDirectory {
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        if ([string]::IsNullOrWhiteSpace($SourceRepo)) { throw 'Supply -SourceRepo or -OutputDirectory.' }
        $script:OutputDirectory = Join-Path $SourceRepo 'out\publish\v1'
    }
    $script:OutputDirectory = [IO.Path]::GetFullPath($script:OutputDirectory)
}
function Assert-AMD64Executable([string] $Exe) {
    Require-File $Exe 'compiled MJFSv1.exe'
    $stream = [IO.File]::Open($Exe,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try {
        if ($stream.Length -lt 1024) { throw 'PE file is unexpectedly small.' }
        $reader = New-Object IO.BinaryReader -ArgumentList $stream
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw 'Executable is missing MZ signature.' }
        [void]$stream.Seek(0x3C,[IO.SeekOrigin]::Begin)
        $header = $reader.ReadInt32()
        if ($header -lt 0x40 -or $header -gt ($stream.Length - 28)) { throw 'Invalid PE header offset.' }
        [void]$stream.Seek($header,[IO.SeekOrigin]::Begin)
        if ($reader.ReadUInt32() -ne 0x00004550) { throw 'Executable is missing PE signature.' }
        if ($reader.ReadUInt16() -ne 0x8664) { throw 'Executable machine is not AMD64.' }
        [void]$stream.Seek(($header + 24),[IO.SeekOrigin]::Begin)
        if ($reader.ReadUInt16() -ne 0x20B) { throw 'Executable optional header is not PE32+.' }
    } finally { $stream.Dispose() }
}
function Assert-CurrentSource([string] $Repo,[string] $Exe) {
    $inputs = @(
        (Join-Path $Repo 'src\ui.cpp'),
        (Join-Path $Repo 'src\resize_row_reclaim_policy_p9np.hpp')
    )
    $exeTimestamp = (Get-Item -LiteralPath $Exe).LastWriteTimeUtc
    foreach ($input in $inputs) {
        Require-File $input 'current P9NP source'
        if ($exeTimestamp -lt (Get-Item -LiteralPath $input).LastWriteTimeUtc) {
            throw ('Executable is older than production source: ' + $input)
        }
    }
}
function Stage-Documentation {
    $repo = Ensure-PublicCheckout
    $backupRoot = Join-Path $repo ('out\publication-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    $backups = 0
    foreach ($relative in $DocumentationFiles) {
        $native = $relative.Replace('/','\')
        $source = Join-Path $KitRoot $native
        $destination = Join-Path $repo $native
        Require-File $source 'publication documentation'
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        if ([IO.Path]::GetFullPath($source).Equals([IO.Path]::GetFullPath($destination),[StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        if (Test-Path -LiteralPath $destination -PathType Leaf) {
            $newHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
            $oldHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            if ($newHash -eq $oldHash) { continue }
            $backup = Join-Path $backupRoot $native
            New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
            Copy-Item -LiteralPath $destination -Destination $backup -Force
            $backups++
        }
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
    Write-Host ('[MJFS PUBLISH] Stage PASS: ' + $DocumentationFiles.Count + ' approved repository paths; backups=' + $backups)
    if ($backups -gt 0) { Write-Host ('[MJFS PUBLISH] Replaced-file backups: ' + $backupRoot) }
}
function Package-Release {
    if ([string]::IsNullOrWhiteSpace($SourceRepo)) { throw 'Supply -SourceRepo pointing to private MJFS production source.' }
    $repo = [IO.Path]::GetFullPath($SourceRepo)
    Require-Directory $repo 'private production checkout'
    $runner = Join-Path $repo 'MJFS-PORTABLE-P9NP.cmd'
    Require-File $runner 'P9NP qualification runner'
    if (-not $SkipBuild) {
        foreach ($step in @('Verify','BuildTests','BuildRelease')) {
            Write-Host ('[MJFS PUBLISH] Production ' + $step + '...')
            & $runner $step
            if ($LASTEXITCODE -ne 0) { throw ('P9NP ' + $step + ' failed; refusing release packaging.') }
        }
    } else {
        Write-Warning 'SkipBuild requested: native tests and fresh compilation have not been repeated.'
    }
    $exe = Join-Path $repo 'dist\MJFSv1.exe'
    Assert-AMD64Executable $exe
    Assert-CurrentSource $repo $exe
    Resolve-OutputDirectory
    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
    $zip = Join-Path $OutputDirectory 'MJFSv1.zip'
    $localManifest = Join-Path $OutputDirectory 'RELEASE-MANIFEST.json'
    $temporary = Join-Path $OutputDirectory ('staging-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temporary | Out-Null
    try {
        $stagedExe = Join-Path $temporary 'MJFSv1.exe'
        $stagedSums = Join-Path $temporary 'SHA256SUMS.txt'
        Copy-Item -LiteralPath $exe -Destination $stagedExe
        $exeHash = (Get-FileHash -LiteralPath $stagedExe -Algorithm SHA256).Hash.ToLowerInvariant()
        [IO.File]::WriteAllText($stagedSums,($exeHash + '  MJFSv1.exe' + "`n"),[Text.Encoding]::ASCII)
        if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::Open($zip,[IO.Compression.ZipArchiveMode]::Create)
        try {
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$stagedExe,'MJFSv1.exe',[IO.Compression.CompressionLevel]::Optimal)
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$stagedSums,'SHA256SUMS.txt',[IO.Compression.CompressionLevel]::Optimal)
        } finally { $archive.Dispose() }
        $data = [ordered]@{
            release = 'v1'; repository = $ExpectedRepository; asset = 'MJFSv1.zip'
            archiveSha256 = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
            executableSha256 = $exeHash; executableBytes = (Get-Item -LiteralPath $exe).Length
            zipBytes = (Get-Item -LiteralPath $zip).Length
            filesInsideZip = @('MJFSv1.exe','SHA256SUMS.txt')
            build = 'native x64 Release (P9NP qualified on publishing host)'
            packagedUtc = [DateTime]::UtcNow.ToString('o')
        }
        [IO.File]::WriteAllText($localManifest,($data | ConvertTo-Json -Depth 6),[Text.Encoding]::UTF8)
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
    }
    Verify-Release
    Write-Host ('[MJFS PUBLISH] Package PASS: ' + $zip + ' (sole GitHub Release asset)')
    Write-Host ('[MJFS PUBLISH] Local audit manifest (NOT uploaded): ' + $localManifest)
}
function Verify-Release {
    Resolve-OutputDirectory
    $zip = Join-Path $OutputDirectory 'MJFSv1.zip'
    Require-File $zip 'MJFSv1.zip'
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('mjfs-release-check-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temp | Out-Null
    try {
        $archive = [IO.Compression.ZipFile]::OpenRead($zip)
        try {
            $names = @($archive.Entries | ForEach-Object { $_.FullName })
            if ($names.Count -ne 2 -or $names[0] -ne 'MJFSv1.exe' -or $names[1] -ne 'SHA256SUMS.txt') {
                throw 'MJFSv1.zip must contain exactly MJFSv1.exe and SHA256SUMS.txt at its root.'
            }
        } finally { $archive.Dispose() }
        [IO.Compression.ZipFile]::ExtractToDirectory($zip,$temp)
        $exe = Join-Path $temp 'MJFSv1.exe'
        $sums = Join-Path $temp 'SHA256SUMS.txt'
        Assert-AMD64Executable $exe
        Require-File $sums 'ZIP-internal SHA256SUMS.txt'
        $lines = @([IO.File]::ReadAllLines($sums))
        if ($lines.Count -ne 1 -or $lines[0] -cnotmatch '^[0-9a-f]{64}  MJFSv1\.exe$') {
            throw 'Checksum file must contain one 64-character lowercase SHA256 for MJFSv1.exe.'
        }
        $expected = $lines[0].Substring(0,64)
        $actual = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($expected -cne $actual) { throw 'Extracted executable SHA256 does not match the bundled checksum.' }
        Write-Host '[MJFS PUBLISH] Verify PASS: exactly 2 ZIP entries, PE32+ AMD64 and SHA256.'
        Write-Host ('[MJFS PUBLISH] EXE SHA256: ' + $actual)
        Write-Host ('[MJFS PUBLISH] ZIP SHA256 (local audit): ' + (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant())
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }
}
function Assert-GitHubPublicRepository {
    # Public repository identity is checked using GitHub's anonymous read-only REST endpoint.
    # No GitHub CLI, token, or write occurs here.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $uri = 'https://api.github.com/repos/' + $ExpectedRepository
    $headers = @{ 'Accept' = 'application/vnd.github+json'; 'User-Agent' = 'MJFSv1-Git-Publisher'; 'X-GitHub-Api-Version' = '2026-03-10' }
    $info = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    if ($info.full_name -cne $ExpectedRepository -or [bool]$info.private) {
        throw ('Expected exact public GitHub repository ' + $ExpectedRepository)
    }
}
function Get-GitHubApiToken {
    # First-party Git Credential Manager credentials can be re-used for the GitHub API.
    # Do not print, persist, put on a command line, or publish the token.
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        return $env:GITHUB_TOKEN.Trim()
    }
    $inputLines = "protocol=https`nhost=github.com`n`n"
    $reply = @($inputLines | & git.exe credential fill)
    if ($LASTEXITCODE -ne 0) {
        throw 'No usable Git HTTPS credentials. Push mode works with Git alone; for API publication set GITHUB_TOKEN or finish on the GitHub Releases page.'
    }
    foreach ($line in $reply) {
        if ($line -cmatch '^password=(.+)$') { return $Matches[1] }
    }
    throw 'Git credential helper returned no HTTPS token. Use -Mode Push and publish the ZIP in your browser, or supply GITHUB_TOKEN for REST publication.'
}
function Get-GitHubHeaders([string] $Token) {
    return @{
        'Accept' = 'application/vnd.github+json'
        'Authorization' = ('Bearer ' + $Token)
        'User-Agent' = 'MJFSv1-Git-Publisher'
        'X-GitHub-Api-Version' = '2026-03-10'
    }
}
function Get-GitHubRelease([hashtable] $Headers) {
    $endpoint = 'https://api.github.com/repos/' + $ExpectedRepository + '/releases?per_page=100'
    $response = Invoke-RestMethod -Method Get -Uri $endpoint -Headers $Headers
    $all = @()
    if ($null -ne $response) { $all = @($response) }
    $matchingReleases = @($all | Where-Object { $_.tag_name -ceq $ReleaseTag })
    if ($matchingReleases.Count -gt 1) { throw 'Multiple releases with the same tag; manual review required.' }
    if ($matchingReleases.Count -eq 1) { return $matchingReleases[0] }
    return $null
}
function Assert-ReleaseAsset([object] $Release,[string] $ZipPath) {
    $assetEndpoint = 'https://api.github.com/repos/' + $ExpectedRepository + '/releases/' + $Release.id + '/assets?per_page=100'
    $assetResponse = Invoke-RestMethod -Method Get -Uri $assetEndpoint -Headers $script:GitHubApiHeaders
    $assets = @()
    if ($null -ne $assetResponse) { $assets = @($assetResponse) }
    if ($assets.Count -gt 1) { throw 'Release has more than one asset; refusing to alter it.' }
    if ($assets.Count -eq 0) { return $false }
    $one = $assets[0]
    if ($one.name -cne 'MJFSv1.zip' -or $one.state -ne 'uploaded') {
        throw 'Release already contains a different/unusable asset; refusing to replace it.'
    }
    if ([int64]$one.size -ne [int64](Get-Item -LiteralPath $ZipPath).Length) {
        throw 'Existing remote ZIP size differs from the verified local package; refusing overwrite.'
    }
    $digestProperty = $one.PSObject.Properties['digest']
    if ($null -ne $digestProperty -and ([string]$digestProperty.Value -cmatch '^sha256:([0-9a-fA-F]{64})$')) {
        $expectedHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($Matches[1].ToLowerInvariant() -cne $expectedHash) {
            throw 'Remote ZIP SHA256 differs from the local verified release; refusing overwrite.'
        }
    } else {
        Write-Warning 'GitHub did not supply an asset SHA256 digest; identity is confirmed only by asset name and byte length.'
    }
    return $true
}
function Push-Documentation {
    if ([string]::IsNullOrWhiteSpace($SourceRepo)) { throw 'Supply -SourceRepo to enforce private/public checkout separation.' }
    Verify-Release
    Assert-GitHubPublicRepository
    $repo = Ensure-PublicCheckout
    Push-Location -LiteralPath $repo
    try {
        $preStaged = @(& git.exe diff --cached --name-only)
        if ($LASTEXITCODE -ne 0) { throw 'Could not inspect staged changes.' }
        if ($preStaged.Count -gt 0) { throw 'Public checkout already has staged changes; commit or unstage first.' }
        Stage-Documentation
        & git.exe add -- $DocumentationFiles
        if ($LASTEXITCODE -ne 0) { throw 'Could not stage approved public repository files.' }
        $staged = @(& git.exe diff --cached --name-only)
        if ($LASTEXITCODE -ne 0) { throw 'Could not inspect public staging.' }
        foreach ($f in $staged) {
            if ($DocumentationFiles -notcontains $f) { throw ('Unapproved staged file: ' + $f) }
        }
        & git.exe diff --cached --quiet
        if ($LASTEXITCODE -eq 1) {
            & git.exe commit -m 'docs: publish MJFS v1 public repository' | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Git commit failed; check Git author configuration.' }
        } elseif ($LASTEXITCODE -ne 0) { throw 'Git index inspection failed.' }
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & git.exe push -u origin ('HEAD:refs/heads/' + $ExpectedBranch) | Out-Null
            $exitCode = $LASTEXITCODE
        } finally { $ErrorActionPreference = $savedPreference }
        if ($exitCode -ne 0) { throw 'Git push failed; no Release upload was attempted.' }
        Write-Host ('[MJFS PUBLISH] Git push PASS: https://github.com/' + $ExpectedRepository + ' (main)')
        return $repo
    } finally { Pop-Location }
}
function Publish-GitHubWithGitAndRest {
    # Publishing must remain retryable after a push, draft creation or ZIP upload failure.
    # Create a draft first, upload exactly one asset, then publish only when verified.
    $repo = Push-Documentation
    $token = Get-GitHubApiToken
    $script:GitHubApiHeaders = Get-GitHubHeaders $token
    $zip = Join-Path $OutputDirectory 'MJFSv1.zip'
    $notesPath = Join-Path $repo 'docs\RELEASE_NOTES_v1.md'
    Require-File $notesPath 'public release notes'
    $release = Get-GitHubRelease $script:GitHubApiHeaders
    if ($null -eq $release) {
        # Existing remote tags are safe only if they point at this exact public HEAD.
        $remoteTags = @(& git.exe -C $repo ls-remote --tags origin ('refs/tags/' + $ReleaseTag))
        if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect existing remote release tag.' }
        if ($remoteTags.Count -gt 0) {
            $head = (& git.exe -C $repo rev-parse HEAD | Out-String).Trim()
            if ($LASTEXITCODE -ne 0 -or $remoteTags[0].Split([char]9)[0] -cne $head) {
                throw 'Remote tag v1 points to a different commit. Refusing to retarget it.'
            }
        }
        $notes = [IO.File]::ReadAllText($notesPath)
        $payload = @{
            tag_name = $ReleaseTag
            target_commitish = $ExpectedBranch
            name = 'MJFS v1'
            body = $notes
            draft = $true
            prerelease = $false
            generate_release_notes = $false
        } | ConvertTo-Json -Depth 4
        $utf8Json = [Text.Encoding]::UTF8.GetBytes($payload)
        $release = Invoke-RestMethod -Uri ('https://api.github.com/repos/' + $ExpectedRepository + '/releases') -Method Post -Headers $script:GitHubApiHeaders -ContentType 'application/json; charset=utf-8' -Body $utf8Json
        Write-Host '[MJFS PUBLISH] Created draft release v1 (not yet public).'
    }
    if ($release.tag_name -cne $ReleaseTag) { throw 'Unexpected release tag returned by GitHub.' }
    $hasAsset = Assert-ReleaseAsset $release $zip
    if (-not $hasAsset) {
        if (-not [bool]$release.draft) { throw 'Existing published release has no ZIP; refusing to modify it automatically.' }
        $uploadUrl = ([string]$release.upload_url) -replace '\{.*$',''
        if (-not $uploadUrl.StartsWith('https://uploads.github.com/repos/' + $ExpectedRepository + '/releases/', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'GitHub returned an unexpected release upload endpoint.'
        }
        $uploadUrl += '?name=MJFSv1.zip'
        # Invoke-RestMethod uploads the raw ZIP bytes (not multipart/form-data).
        $uploaded = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $script:GitHubApiHeaders -ContentType 'application/zip' -InFile $zip
        if ($uploaded.name -cne 'MJFSv1.zip' -or $uploaded.state -ne 'uploaded') { throw 'Asset upload did not finish successfully.' }
        Write-Host '[MJFS PUBLISH] Uploaded MJFSv1.zip to draft release.'
    }
    if (-not (Assert-ReleaseAsset $release $zip)) { throw 'ZIP asset is absent after upload.' }
    if ([bool]$release.draft) {
        $change = [Text.Encoding]::UTF8.GetBytes('{"draft":false}')
        $release = Invoke-RestMethod -Uri ('https://api.github.com/repos/' + $ExpectedRepository + '/releases/' + $release.id) -Method Patch -Headers $script:GitHubApiHeaders -ContentType 'application/json; charset=utf-8' -Body $change
        if ([bool]$release.draft) { throw 'Release remains draft; inspect GitHub before retrying.' }
    }
    if (-not (Assert-ReleaseAsset $release $zip)) { throw 'Published release asset verification failed.' }
    Write-Host ('[MJFS PUBLISH] Publish PASS: https://github.com/' + $ExpectedRepository + '/releases/tag/' + $ReleaseTag)
    Write-Host '[MJFS PUBLISH] Exactly one release asset: MJFSv1.zip (EXE + SHA256SUMS.txt).'
}

try {
    switch ($Mode) {
        'Stage'   { Stage-Documentation }
        'Package' { Package-Release }
        'Verify'  { Verify-Release }
        'Push'    { $null = Push-Documentation; Write-Host '[MJFS PUBLISH] Git-only push PASS. To upload MJFSv1.zip without an API token, open https://github.com/MarceloAlejandroJorquera/MJFS/releases/new and create release v1.' }
        'Publish' { Publish-GitHubWithGitAndRest }
    }
} catch {
    Write-Error ('[MJFS PUBLISH] ' + $_.Exception.Message)
    exit 1
}
