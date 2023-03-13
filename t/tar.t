use Mojo::Base -strict, -signatures;
use Test2::V0;

use Mojo::Collection qw(c);
use Mojo::File       qw(path);
use Mojo::Tar;

my $example = path(qw(t example.tar));
plan skip_all => 'Cannot open t/example.tar' unless -r "$example";

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

subtest 'extract' => sub {
  my $tar = Mojo::Tar->new;
  ok !$tar->is_complete, 'not complete';

  my $files = c();
  $tar->on(extracted => sub ($tar, $file) { push @$files, $file });

  my $fh = $example->open('<');
  while (1) {
    sysread $fh, my ($chunk), int(448 + rand 128) or last;
    $tar->extract($chunk);
  }

  is $files->size,                  11, 'extracted all files';
  is $files->map('type')->to_array, [0,    0,  5, 5, 5, 5, 5, 5, 5, 0,  0],   'type';
  is $files->map('size')->to_array, [1427, 86, 0, 0, 0, 0, 0, 0, 0, 23, 409], 'size';
  ok $tar->is_complete, 'is complete';

  my $file = $files->first;
  is $file->path,                 'Makefile.PL', 'file path';
  isnt $file->asset->path,        $file->path,   'asset is a temp file';
  is length($file->asset->slurp), $file->size,   'extracted file has matching file size';
};

done_testing;
