package Mojo::Tar;
use Mojo::Base -base, -signatures;

use Mojo::Tar::File;

use constant TAR_BLOCK_SIZE => 512;

our $VERSION = '0.01';

sub looks_like_tar ($self, $bytes) {
  state $padding = "\0" x TAR_USTAR_PADDING_LEN;
  return
      length($bytes) < TAR_BLOCK_SIZE                                          ? 0
    : substr($bytes, TAR_USTAR_PADDING_POS, TAR_USTAR_PADDING_LEN) ne $padding ? 0
    : Mojo::Tar::File->new->from_header($bytes)->checksum                      ? 1
    :                                                                            0;
}

1;
