dupes: a duplicate files tool
=============================

`dupes` was written to find and delete duplicate files, because I was dissatisfied with the existing solutions that I found.

I wanted my tool to:

 * work well from a remote shell
 * work well with files spread across network storage
 * incrementally handle changes to files
 * leverage existing tools

It is based on a database and hashing, so that work can be done incrementally. Files paths are read from the standard input by default, which enables me to take advantage of `find`, which is in the business of finding files.

Usage
-----

Add files to the `dupes` database, recording their sizes (by default, a database is created in your home directory):

```
$ find ~ -type f | dupes add
```

Hash all files in the database which haven't been hashed, but have the same size as other indexed files:

```
$ dupes hash
```

List all duplicate files, in groups:

```
$ dupes list
```

Interact with the list of duplicates in a way which allows easy manual marking of files for deletion:

```
$ dupes interactive
```

See all possible commands:

```
$ dupes help
```

Caveats
-------

File comparison is based on hashes (currently MD5). Having indexed ~1m files form my home directory, less than 10k files share the modal size, which gives a minuscule probability of a collision.

Dependencies
------------

dupes is a command line tool, and I didn't want to depend on external frameworks, which would complicate installation. It is written in Swift, which currently doesn't support static libraries. So, some code has been borrowed, only slightly modified, from other open source projects:

 * [Commandant](https://github.com/Carthage/Commandant) (MIT licensed)
 * [PathKit](https://github.com/kylef/PathKit) (BSD 2-Clause licensed)
 * [Result](https://github.com/antitypical/Result) (MIT licensed)
 * [SQLite.swift](https://github.com/stephencelis/SQLite.swift) (MIT licensed)
