use strict;
use warnings;

use Test::More;# tests => 5;

plan skip_all => 'coming soon';

use Test::DZil;

my $dist_ini = dist_ini({
        name     => 'DZT-Sample',
        abstract => 'Sample DZ Dist',
        author   => 'E. Xavier Ample <example@example.org>',
        license  => 'Perl_5',
        copyright_holder => 'E. Xavier Ample',
    }, qw/
        GatherDir
        NextRelease
        FakeRelease
    /,
    #ChangeStats::Git
    );

my $tzil = Builder->from_config(
    { dist_root => 'corpus' },
    #  {
    #        'source/dist.ini' => $dist_ini
    #    },
);

$tzil->build;

like $tzil->slurp_file('build/Changes'),
    qr/
\[STATISTICS\]\s*\n
\s*-\s*code\schurn:\s+\d+\sfiles\schanged,
\s\d+\sinsertions\(\+\),\s\d+\sdeletions\(-\)
    /x,
    "stats added";
