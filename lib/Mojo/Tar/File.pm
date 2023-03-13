package Mojo::Tar::File;
use Mojo::Base -base, -signatures;

use Carp       qw(croak);
use Exporter   qw(import);
use Mojo::File ();

use constant DEBUG => !!$ENV{MOJO_TAR_DEBUG};

our ($PACK_FORMAT, @EXPORT);

BEGIN {
  $PACK_FORMAT = q(
    a100 # pos=0   name=name      desc=file name (chars)
    a8   # pos=100 name=mode      desc=file mode (octal)
    a8   # pos=108 name=uid       desc=uid (octal)
    a8   # pos=116 name=gid       desc=gid (octal)
    a12  # pos=124 name=size      desc=size (octal)
    a12  # pos=136 name=mtime     desc=mtime (octal)
    a8   # pos=148 name=checksum  desc=checksum (octal)
    a1   # pos=156 name=type      desc=type
    a100 # pos=157 name=symlink   desc=file symlink destination (chars)
    A6   # pos=257 name=ustar     desc=ustar
    a2   # pos=263 name=ustar_ver desc=ustar version (00)
    a32  # pos=265 name=owner     desc=owner user name (chars)
    a32  # pos=297 name=group     desc=owner group name (chars)
    a8   # pos=329 name=dev_major desc=device major number
    a8   # pos=337 name=dev_minor desc=device minor number
    a155 # pos=345 name=prefix    desc=file name prefix
    a12  # pos=500 name=padding   desc=padding (\0)
  );

  # Generate constants:
  # TAR_USTAR_NAME_LEN       TAR_USTAR_NAME_POS
  # TAR_USTAR_MODE_LEN       TAR_USTAR_MODE_POS
  # TAR_USTAR_UID_LEN        TAR_USTAR_UID_POS
  # TAR_USTAR_GID_LEN        TAR_USTAR_GID_POS
  # TAR_USTAR_SIZE_LEN       TAR_USTAR_SIZE_POS
  # TAR_USTAR_MTIME_LEN      TAR_USTAR_MTIME_POS
  # TAR_USTAR_CHECKSUM_LEN   TAR_USTAR_CHECKSUM_POS
  # TAR_USTAR_TYPE_LEN       TAR_USTAR_TYPE_POS
  # TAR_USTAR_SYMLINK_LEN    TAR_USTAR_SYMLINK_POS
  # TAR_USTAR_USTAR_LEN      TAR_USTAR_USTAR_POS
  # TAR_USTAR_USTAR_VER_LEN  TAR_USTAR_USTAR_VER_POS
  # TAR_USTAR_OWNER_LEN      TAR_USTAR_OWNER_POS
  # TAR_USTAR_GROUP_LEN      TAR_USTAR_GROUP_POS
  # TAR_USTAR_DEV_MAJOR_LEN  TAR_USTAR_DEV_MAJOR_POS
  # TAR_USTAR_DEV_MINOR_LEN  TAR_USTAR_DEV_MINOR_POS
  # TAR_USTAR_PREFIX_LEN     TAR_USTAR_PREFIX_POS
  # TAR_USTAR_PADDING_LEN    TAR_USTAR_PADDING_POS
  for my $line (split /\n/, $PACK_FORMAT) {
    my ($len, $pos, $name) = $line =~ /(\d+)\W+pos=(\d+)\W+name=(\w+)/ or next;

    my $const = uc "TAR_USTAR_${name}_LEN";
    constant->import($const => $len);
    push @EXPORT, $const;

    $const = uc "TAR_USTAR_${name}_POS";
    constant->import($const => $pos);
    push @EXPORT, $const;
  }
}

has asset => sub ($self) {Mojo::File::tempfile};
has checksum =>
  sub ($self) { substr $self->to_header, TAR_USTAR_CHECKSUM_POS, TAR_USTAR_CHECKSUM_LEN };
has dev_major => '';
has dev_minor => '';
has gid       => sub ($self) { $self->{asset} && $self->asset->stat->gid || $( };
has group     => sub ($self) { getgrgid($self->gid)                      || '' };
has is_complete =>
  sub ($self) { $self->{asset} && $self->asset->stat->size == $self->size ? 1 : 0 };
has mode    => sub ($self) { $self->{asset} && $self->asset->stat->mode  || 0 };
has mtime   => sub ($self) { $self->{asset} && $self->asset->stat->mtime || time };
has owner   => sub ($self) { getpwuid($self->uid) || '' };
has path    => sub ($self) { $self->{asset} && $self->asset->to_string  || '' };
has size    => sub ($self) { $self->{asset} && $self->asset->stat->size || 0 };
has symlink => '';
has type    => sub ($self) { $self->_build_type };
has uid     => sub ($self) { $self->{asset} && $self->asset->stat->uid || $( };

sub add_block ($self, $block) {
  return $self unless $self->type eq 0;

  $self->{bytes_added} //= 0;
  my $chunk = substr $block, 0, $self->size - $self->{bytes_added};
  $self->{bytes_added} += length $chunk;
  croak 'File size is out of range' if $self->{bytes_added} > $self->size;

  my $handle = $self->{add_block_handle} //= $self->asset->open('>');
  ($handle->syswrite($chunk) // -1) == length $chunk or croak "Can't write to asset: $!";
  $self->is_complete(1)->_cleanup if $self->{bytes_added} == $self->size;

  warn sprintf "[tar:add_block] chunk=%s/%s size=%s/%s is_complete=%s path=%s\n", length($chunk),
    length($block), $self->{bytes_added}, $self->size, $self->is_complete, $self->path
    if DEBUG;

  return $self;
}

sub from_header ($self, $header) {
  my @fields   = unpack $PACK_FORMAT, $header;
  my $checksum = $self->_checksum($header);

  $self->path(_trim_nul($fields[0]));    # TODO: Use slot #15 as well
  $self->mode(_from_oct($fields[1]));
  $self->uid(_from_oct($fields[2]));
  $self->gid(_from_oct($fields[3]));
  $self->size(_from_oct($fields[4]));
  $self->mtime(_from_oct($fields[5]));
  $self->checksum($checksum eq $fields[6] =~ s/\0\s$//r ? $checksum : '');
  $self->type($fields[7] eq "\0"                        ? '0'       : $fields[7]);
  $self->symlink(_trim_nul($fields[8]));
  $self->owner(_trim_nul($fields[11]));
  $self->group(_trim_nul($fields[12]));
  $self->dev_major($fields[13]);
  $self->dev_minor($fields[14]);

  warn sprintf "[tar:from_header] %s\n", join ' ',
    map { sprintf '%s=%s', $_, $self->$_ }
    qw(path mode uid gid size mtime checksum type symlink owner group)
    if DEBUG;

  return $self;
}

sub to_header ($self) {
  my $prefix = '';                                # TODO: Split path() into [0] and [15]
  my $header = pack $PACK_FORMAT, $self->path,    # 0
    sprintf('%06o ',  $self->mode),               # 1
    sprintf('%06o ',  $self->uid),                # 2
    sprintf('%06o ',  $self->gid),                # 3
    sprintf('%011o ', $self->size),               # 4
    sprintf('%011o ', $self->mtime),              # 5
    '',                                           # 6 - checksum
    $self->type,                                  # 7
    $self->symlink,                               # 8
    "ustar\0",                                    # 9 - ustar
    '00',                                         # 10 - ustar version
    $self->owner,                                 # 11
    $self->group,                                 # 12
    sprintf('%07s', $self->dev_major),            # 13
    sprintf('%07s', $self->dev_minor),            # 14
    $prefix,                                      # 15
    '';                                           # 16 - padding

  # Inject checksum
  substr $header, TAR_USTAR_CHECKSUM_POS, TAR_USTAR_CHECKSUM_LEN, $self->_checksum($header) . "\0 ";

  return $header;
}

sub _build_type ($self) {
  return '0' unless my $asset = $self->{asset};
  return '0' if -f $asset;                        # plain file
  return '1' if -l _;                             # symlink
  return '3' if -c _;                             # char dev
  return '4' if -b _;                             # block dev
  return '5' if -d _;                             # directory
  return '6' if -p _;                             # pipe
  return '8' if -s _;                             # socket
  return '2' if $asset->stat->nlink > 1;          # hard link
  return '9';                                     # unknown
}

sub _checksum ($self, $header) {
  return sprintf '%06o', int unpack '%16C*', join '        ',
    substr($header, 0, TAR_USTAR_CHECKSUM_POS), substr($header, TAR_USTAR_TYPE_POS);
}

sub _cleanup ($self) {
  my $handle = delete $self->{add_block_handle};
  $handle->close if $handle;
}

sub _from_oct ($str) {
  $str =~ s/^0+//;
  $str =~ s/[\s\0]+$//;
  return length($str) ? oct $str : 0;
}

sub _trim_nul ($str) {
  my $idx = index $str, "\0";
  return $idx == -1 ? $str : substr $str, 0, $idx;
}

sub DESTROY ($self) { $self->_cleanup }

1;
