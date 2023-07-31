# blackstrap S3

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/metabronx/blackstrap_s3/build.yaml?label=latest%20build&style=flat-square)

An S3 SFTP-enabled file system bridge.

In conjunction with [sdcli](https://github.com/metabronx/sdcli), Blackstrap S3 automatically configures a local SFTP-enabled S3 bridge for BLOB-based file management.

The created container is intended to **only** be run locally, as the SSH configuration is highly insecure for the benefit of
easier local access.

## Background

An S3 object store is _not_ the same thing as a traditional filesystem. A filesystem operates on files that can be opened, altered, renamed, hold metadata (like permissions), and be arranged in hierarchical structures (directory trees). Object stores like S3 operate on "objects," which by design are immutable, permission-less (in the UNIX sense), and flat; there is no concept of directories in the traditional sense.

The directory concept is probably the more foreign quirk of S3. In a traditional filesystem you can organize data like so:

```plain
outer
├── a.txt
└───inner
    └───b.txt
```

An object store would hold the same data more like this:

```plain
outer/a.txt
outer/inner/b.txt
```

In an object store there are no actual directories, only objects that contain slashes in their name. We **interpret** them as directory paths, but they aren't.

> _Fun fact: If you create a folder via the AWS S3 web application, S3 will create "ghost" 0-byte object. It has no meaning or value other than helping UIs visually pretend a folder exists where one doesn't._

## Caveats

Of course, since the intent of Blackstrap S3 is to expose S3 as if it _were_ a normal SFTP-enabled sever, so that you can organize and distribute files between places and people, there are some important caveats.

### Interoperability

At a fundamental level, the operations your computer uses to interact with files in a filesystem are not the same as the ones an S3 tool uses to interact with S3. This is a pretty simple mapping showing the differences:

| POSIX            | S3             |
|------------------|----------------|
| read             | GetObject      |
| write            | PutObject      |
| unlink (delete)  | DeleteObject   |
| readdir          | ListObjectsV2  |
| rename           | CopyObject     |
| chmod            | CopyObject     |
| open             |                |
| lseek            |                |

This makes interacting with S3 tricky. If you want to use S3 as if it were a normal filesystem, software needs to interoperate kernel system calls with the S3 protocol.

There are several different programs that implement the bridge for this gap. Blackstrap S3 uses [s3fs](https://github.com/s3fs-fuse/s3fs-fuse). It's not as fast or POSIX compliant compared to others, but is entirely interoperable with other S3 clients (objects uploaded using it can be viewed / downloading by the AWS CLI, for ex.), has enough POSIX support for SFTP, and supports multiple people on different machines using the same bucket. A detailed comparison is available [here](http://gaul.org/talks/s3fs-tradeoffs).

### Performance

To achieve that POSIX compatibility, certain filesystem operations necessarily must translate to more than one S3 operation. Listing directories is undoubtedly the most expensive - you need to fetch some data from every file in a directory in order to properly see modified/created/accessed times and permissions; 1 filesystem call can turn into hundreds or thousands of network requests.

Conveniently, Amazon S3 charges for data egress in addition to both ingress and storage. Since operations like "list all the files in a directory" require fetching data for every file, these calls are also literally more expensive.

# License

Elias
