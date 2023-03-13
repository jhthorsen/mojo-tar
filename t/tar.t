use Test2::V0;

use Mojo::Tar;

subtest 'constants' => sub {
  is Mojo::Tar::TAR_USTAR_PADDING_POS, 500, 'TAR_USTAR_PADDING_POS';
  is Mojo::Tar::TAR_USTAR_PADDING_LEN, 12,  'TAR_USTAR_PADDING_LEN';
};

done_testing;
