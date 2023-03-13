package Mojo::Tar::File;
use Mojo::Base -base, -signatures;

use Exporter   qw(import);

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

1;
