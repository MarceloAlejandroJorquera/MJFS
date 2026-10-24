# MJFS v1.1 distribution and notices

The only GitHub Release binary asset is `MJFSv1.1.zip`, containing precisely `MJFSv1.1.exe` and `SHA256SUMS.txt` at archive root. Source patch bundles, tests, logs, indexes, journals, service images, build intermediates, private paths and rollback folders are excluded.

The main EXE contains the compiled broker as `RT_RCDATA 102`. Windows SCM requires an actual service process executable: service deployment from the GUI places a separate protected service binary in ProgramData. This operational artifact is not a second distributed ZIP file.

Verify the licensing of embedded fonts, images, icons and third-party dependencies. Do not distribute a standalone font file in the release ZIP. The applicable public repository `LICENSE`, if present, controls the published terms; this documentation does not grant an additional source-code license or replace that file.

Only public documentation files are synchronized to GitHub `main` by the release tool. GitHub release attachment is manual. Any code change, repository permission or licensing modification must be reviewed separately.
