# blackstrap S3

An AWS S3 SFTP-enabled file system bridge.

In conjunction with `sdcli`, Blackstrap S3 automatically configures an SFTP-enabled S3 bridge for BLOB-based file management.

The created container is intended to **only** be run locally, as the SSH configuration is highly insecure for the benefit of
easier local access.

## Caveats

Due to the nature of having filesystem operations interoperate with the S3 protocol, some actions will take longer than others. This will be particularly noticeable when uploading large files and manipulating heavily populated directories.

The root cause of these performance differences has to do with the number of S3 actions a filesystem action gets translated into. For example, renaming a directory actually deletes and recreates all objects under a new prefix (since BLOB storage has no concept of "directories").

As Amazon S3 charges for data ingress and egress in addition to storage, this also means certain operations are literally more expensive than others.

# License

Elias
