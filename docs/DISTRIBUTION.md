# Distribution and third-party notices

The **only GitHub Release asset** is `MJFSv1.zip`, containing `MJFSv1.exe` and `SHA256SUMS.txt`. No source patch archives, build logs, index files, journal data, user searches, or rollback folders are part of the release archive.

The executable build embeds a UI font resource. Before publishing, verify licensing and notices for all embedded fonts, assets and third-party components. Do not separately distribute font files in the release ZIP.

This kit does **not** grant a source-code license. If you later publish source, review ownership and licensing obligations and add an appropriate LICENSE file explicitly. The public documentation-only repository does not provide the private build source.

The release publisher uses Git for repository changes and native PowerShell GitHub REST API calls for GitHub release creation; it has no GitHub CLI dependency. Use `-Mode Push` if you prefer uploading the ZIP through the website.
