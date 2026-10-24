# Distribution and third-party notices

The **only GitHub Release asset** is `MJFSv1.zip`, containing `MJFSv1.exe` and `SHA256SUMS.txt`. No source patch archives, build logs, index files, journal data, user searches, or rollback folders are part of the release archive.

The executable build embeds a UI font resource. Before publishing, verify licensing and notices for all embedded fonts, assets and third-party components. Do not separately distribute font files in the release ZIP.

MJFS v1 is distributed under the [MJFS Binary Distribution License](../LICENSE), which permits use of official unmodified releases but does not grant redistribution or modification rights. The private C++ source code is not published. Third-party materials may have separate license requirements.

The release publisher uses Git for repository changes and native PowerShell GitHub REST API calls for GitHub release creation; it has no GitHub CLI dependency. Use `-Mode Push` if you prefer uploading the ZIP through the website.
