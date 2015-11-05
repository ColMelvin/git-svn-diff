#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 6;
use Test::Repo qw(get_diff cmp_diff cmp_ver get_svn_version);

my $repo = Temp::Repo->new();

my $white = "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00\x25\xdb\x56\xca\x00\x00\x00\x03\x50\x4c\x54\x45\xff\xff\xff\xa7\xc4\x1b\xc8\x00\x00\x00\x0a\x49\x44\x41\x54\x08\xd7\x63\x60\x00\x00\x00\x02\x00\x01\xe2\x21\xbc\x33\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";

my $black = "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00\x25\xdb\x56\xca\x00\x00\x00\x03\x50\x4c\x54\x45\x00\x00\x00\xa7\x7a\x3d\xda\x00\x00\x00\x0a\x49\x44\x41\x54\x08\xd7\x63\x60\x00\x00\x00\x02\x00\x01\xe2\x21\xbc\x33\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";

# Note the lack of newline in the contents.
$repo->svn_new_file("file", $white);
$repo->svn_commit("Initial commit");
{
	local $TODO = "Issue #13";
	test_repo($repo, [qw(-c 1)], "Added a binary file");
}

$repo->svn_overwrite_file("file", $black);
$repo->svn_commit("Modification commit");
$repo->git_run(qw(git checkout -q git-svn));
test_repo($repo, [qw(-c 2)], "Modified the binary file");

{
	local $TODO = "Issue #19" if cmp_ver(get_svn_version(), '1.7') >= 0;
	local $TODO = "Issue #13";
	test_repo($repo, [qw(-r 0:2)], "Diff over multiple commits");
}

$repo->svn_remove_file("file");
$repo->svn_commit("Deletion commit");
$repo->git_run(qw(git checkout -q git-svn));

{
	local $TODO = "Issue #19" if cmp_ver(get_svn_version(), '1.7') >= 0;
	local $TODO = "Issue #13";
	test_repo($repo, [qw(-c 3)], "Deleted the binary file");

	test_repo($repo, [qw(-r 1:3)], "Deletion combination");
}
test_repo($repo, [qw(-r 0:3)], "Empty diff");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;

	my ($got, $expected) = get_diff($repo, args => $args);

	# Until svn:mime-type is supported, this test will fail.
	my $copy = $expected;
	local $TODO = "Issue #12" if $copy =~ s/^svn:mime-type = .*\n$//m && $copy eq $got;

	cmp_diff($got, $expected, $message);
}
