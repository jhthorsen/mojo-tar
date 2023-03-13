package Mojo::Tar;
use Mojo::Base 'Mojo::EventEmitter', -signatures;

use Mojo::Tar::File;

use constant DEBUG          => !!$ENV{MOJO_TAR_DEBUG};
use constant TAR_BLOCK_SIZE => 512;
use constant TAR_BLOCK_PAD  => "\0" x TAR_BLOCK_SIZE;

our $VERSION = '0.01';

has is_complete => 0;

sub extract ($self, $block) {
  if (my $file = $self->{current}) {
    $file->add_block($block);
    $self->emit(extracted => delete $self->{current}) if $file->is_complete;
  }
  elsif ($block eq TAR_BLOCK_PAD) {
    warn "[tar:extract] Got tar pad block\n" if DEBUG;
    return $self->is_complete(1);
  }
  else {
    my $file = Mojo::Tar::File->new->from_header($block);
    $self->is_complete(0)->emit(extracting => $file);
    $file->size ? ($self->{current} = $file) : $self->emit(extracted => $file);
  }

  return $self;
}

sub looks_like_tar ($self, $bytes) {
  state $padding = "\0" x TAR_USTAR_PADDING_LEN;
  return
      length($bytes) < TAR_BLOCK_SIZE                                          ? 0
    : substr($bytes, TAR_USTAR_PADDING_POS, TAR_USTAR_PADDING_LEN) ne $padding ? 0
    : Mojo::Tar::File->new->from_header($bytes)->checksum                      ? 1
    :                                                                            0;
}

1;
