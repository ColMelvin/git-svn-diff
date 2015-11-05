#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    dist_name           => 'git-svn-diff',
    license             => 'gpl',
    dist_author         => q{Chris Lindee <chris.lindee+github@gmail.com>},
    dist_version_from   => 'bin/git-svn-diff',
    build_requires => {
        'Exporter' => 0,
        'FindBin' => 0,
        'File::chdir' => 0,
        'File::Path' => 0,
        'File::Spec' => 0,
        'File::Spec::Unix' => 0,
        'File::Temp' => 0,
        'IPC::Run' => 0,
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
        'File::Basename' => 0,
        'Getopt::Long' => 0,
        'Git' => 0,
    },
    add_to_cleanup      => [ 'git-svn-diff-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
