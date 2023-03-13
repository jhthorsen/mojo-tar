use Test2::V0;

use Mojo::Tar;

subtest 'constants' => sub {
  is Mojo::Tar::TAR_USTAR_PADDING_POS, 500, 'TAR_USTAR_PADDING_POS';
  is Mojo::Tar::TAR_USTAR_PADDING_LEN, 12,  'TAR_USTAR_PADDING_LEN';
};

subtest 'looks_like_tar' => sub {
  my $tar = Mojo::Tar->new;
  is $tar->looks_like_tar(''),                              0, 'short';
  is $tar->looks_like_tar('1' x Mojo::Tar->TAR_BLOCK_SIZE), 0, 'pad missing';

  my $header = Mojo::Tar::File->new->to_header;
  is $tar->looks_like_tar($header), 1, 'looks like tar';

  substr $header, 0, 3, 'xxx';
  is $tar->looks_like_tar($header), 0, 'invalid checksum';
};

done_testing;
