Offline Maven dependency repository for compiling AutoFirma 1.9.2 in Esparto.

Contains 683 third-party JAR and POM artifacts from Maven Central, each pinned
by SHA-256 in the reviewed inventory. GitHub Actions recreates the archive and
checks its SHA-256 against the one reviewed locally before publication.

This archive contains precompiled third-party library and build-tool dependencies.
It does not contain prebuilt AutoFirma modules or Java-WebSocket: the ebuild
compiles those from their separately fetched sources. Library license information
is retained in the original JAR/POM files.

Archive SHA-256: 6ec0426342c3e846dbcb839947156176df5dd16121443ae2b4a9204c34dca50f

Fixed local Maven metadata is generated from the reviewed artifact versions so
version ranges can be resolved offline without consulting mutable remote metadata.
