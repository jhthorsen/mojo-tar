# NAME

Mojo::Tar - Stream your (ustar) tar files

# SYNOPSIS

## Create

    use Mojo::Tar
    my $tar = Mojo::Tar->new;

    $tar->on(adding => sub ($self, $file) {
      warn sprintf qq(Adding "%s" %sb to archive\n), $file->path, $file->size;
    });

    my $cb = $tar->files(['a.baz', 'b.foo'])->create;
    open my $fh, '>', '/path/to/my-archive.tar';
    while (length(my $chunk = $cb->())) {
      print {$fh} $chunk;
    }

## Extract

    use Mojo::Tar
    my $tar = Mojo::Tar->new;

    $tar->on(extracted => sub ($self, $file) {
      warn sprintf qq(Extracted "%s" %sb\n), $file->path, $file->size;
    });

    open my $fh, '<', '/path/to/my-archive.tar';
    while (1) {
      sysread $fh, my ($chunk), 512 or die $!;
      $tar->extract($chunk);
    }

# DESCRIPTION

[Mojo::Tar](https://metacpan.org/pod/Mojo%3A%3ATar) can create and extract [ustar](http://www.gnu.org/software/tar/manual/tar.html)
tar files as a stream. This can be useful if for example your webserver is
receiving a big tar file and you don't want to exhaust the memory while
reading it.

The [pax](http://www.opengroup.org/onlinepubs/007904975/utilities/pax.html)
tar format is not planned, but a pull request is more than welcome!

Note that this module is currently EXPERIMENTAL, but the API will only change
if major design issues is discovered.

# EVENTS

## added

    $tar->on(added => sub ($tar, $file) { ... });

Emitted after the callback from ["create"](#create) has returned all the content of the `$file`.

## adding

    $tar->on(adding => sub ($tar, $file) { ... });

Emitted right before the callback from ["create"](#create) returns the tar header for the
`$file`.

## created

    $tar->on(created => sub ($tar, @) { ... });

Emitted right before the callback from ["create"](#create) returns the last chunk of the tar
file.

## extracted

    $tar->on(extracted => sub ($tar, $file) { ... });

Emitted when ["extract"](#extract) has read the complete content of the file.

## extracting

    $tar->on(extracting => sub ($tar, $file) { ... });

Emitted when ["extract"](#extract) has read the tar header for a [Mojo::Tar::File](https://metacpan.org/pod/Mojo%3A%3ATar%3A%3AFile). This
event can be used to set the ["asset" in Mojo::Tar::File](https://metacpan.org/pod/Mojo%3A%3ATar%3A%3AFile#asset) to something else than a
temp file.

# ATTRIBUTES

## files

    $tar = $tar->files(Mojo::Collection->new('a.file', ...)]);
    $tar = $tar->files([Mojo::File->new]);
    $tar = $tar->files([Mojo::Tar::File->new, ...]);
    $collection = $tar->files;

This attribute holds a [Mojo::Collection](https://metacpan.org/pod/Mojo%3A%3ACollection) of [Mojo::Tar::File](https://metacpan.org/pod/Mojo%3A%3ATar%3A%3AFile) objects which
is used by either ["create"](#create) or ["extract"](#extract).

Setting this attribute will make sure each item is a [Mojo::Tar::File](https://metacpan.org/pod/Mojo%3A%3ATar%3A%3AFile) object,
even if the original list contained a [Mojo::File](https://metacpan.org/pod/Mojo%3A%3AFile) or a plain string.

## is\_complete

    $bool = $tar->is_complete;

True when the callback from ["create"](#create) has returned the whole tar-file or when
["extract"](#extract) thinks the whole tar file has been read.

Note that because of this, ["create"](#create) and ["extract"](#extract) should not be called on
the same object.

# METHODS

## create

    $cb = $tar->create;

This method will take ["files"](#files) and return a callback that will return a chunk
of the tar file each time it is called, and an empty string when all files has
been processed. Example:

    while (length(my $chunk = $cb->())) {
      warn sprintf qq(Got %sb of tar data\n), length $chunk;
    }

The ["adding"](#adding) and ["added"](#added) events will be emitted for each file and the
["created"](#created) event will be emitted at the very end. In addition ["is\_complete"](#is_complete)
will also be set right before ["created"](#created) gets emitted.

## extract

    $tar = $tar->extract($bytes);

Used to parse `$bytes` and turn the information into [Mojo::Tar::File](https://metacpan.org/pod/Mojo%3A%3ATar%3A%3AFile)
objects which are emitted as ["extracting"](#extracting) and ["extracted"](#extracted) events.

## looks\_like\_tar

    $bool = $tar->looks_like_tar($bytes);

Returns true if [Mojo::Tar](https://metacpan.org/pod/Mojo%3A%3ATar) thinks `$bytes` looks like the beginning of a
tar stream. Currently this checks if `$bytes` is at least 512 bytes long and
the checksum value in the tar header is correct.

## new

    $tar = Mojo::Tar->new(\%attrs);
    $tar = Mojo::Tar->new(%attrs);

Used to create a new [Mojo::Tar](https://metacpan.org/pod/Mojo%3A%3ATar) object. ["files"](#files) will be normalized.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar)
