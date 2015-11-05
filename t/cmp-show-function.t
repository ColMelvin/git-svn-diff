#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More;
use Test::Repo qw(get_svn_version cmp_ver);

plan skip_all => "Option “--show-c-function” not available before SVN v1.5" if cmp_ver(get_svn_version(), "1.5") < 0;
plan tests => 2;

my $repo = Temp::Repo->new();

$repo->svn_new_file("main.c", <<SOURCE);
#include <stdio.h>

int main()
{
	const int c = 299792458;

	printf("Speed of Light (vacuum): %d m/s\\n", c);

	return 0;
}
SOURCE
$repo->svn_commit("Initial commit");
test_repo($repo, [qw(-c 1)], "Don't show C function in chunk header");

$repo->svn_overwrite_file("main.c", <<SOURCE);
#include <stdio.h>

int main()
{
	const int c = 299792458;

	printf("Speed of Light (vacuum): %d km/s\\n", c / 1000);

	return 0;
}
SOURCE
$repo->svn_commit("Specify speed in km/s");
$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-c 2)], "Show C function in chunk header");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, svn_args => [qw(-x --show-c-function)], name => $message);
}
