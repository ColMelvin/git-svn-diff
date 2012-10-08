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
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'Getopt::Long' => 0,
	'Git' => 0,
	'Pod::Usage' => 0,
    },
    add_to_cleanup      => [ 'git-svn-diff-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
