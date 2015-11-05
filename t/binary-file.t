#!/usr/bin/perl

# SVN has changed its diff options & output for binary files over time, so we
# can't rely on the SVN binary's output.  So we compare to a static list that
# approximates SVN 1.6.

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 6;
use Test::Repo qw(cmp_diff);

my $repo = Temp::Repo->new();

my $white = "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00\x25\xdb\x56\xca\x00\x00\x00\x03\x50\x4c\x54\x45\xff\xff\xff\xa7\xc4\x1b\xc8\x00\x00\x00\x0a\x49\x44\x41\x54\x08\xd7\x63\x60\x00\x00\x00\x02\x00\x01\xe2\x21\xbc\x33\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";

my $black = "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00\x25\xdb\x56\xca\x00\x00\x00\x03\x50\x4c\x54\x45\x00\x00\x00\xa7\x7a\x3d\xda\x00\x00\x00\x0a\x49\x44\x41\x54\x08\xd7\x63\x60\x00\x00\x00\x02\x00\x01\xe2\x21\xbc\x33\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";

# Note the lack of newline in the contents.
$repo->svn_new_file("file", $white);
$repo->svn_commit("Initial commit");

my $got = $repo->git_svn_diff(qw(-c 1));
my $expected = <<DIFF;
Index: file
===================================================================
Cannot display: file marked as a binary type.
DIFF
cmp_diff($got, $expected, "Added a binary file");

$repo->svn_overwrite_file("file", $black);
$repo->svn_commit("Modification commit");
$repo->git_run(qw(git checkout -q git-svn));

$got = $repo->git_svn_diff(qw(-c 2));
cmp_diff($got, $expected, "Modified the binary file");

$got = $repo->git_svn_diff(qw(-r 0:2));
cmp_diff($got, $expected, "Diff over multiple commits");

$repo->svn_remove_file("file");
$repo->svn_commit("Deletion commit");
$repo->git_run(qw(git checkout -q git-svn));

$got = $repo->git_svn_diff(qw(-c 2));
cmp_diff($got, $expected, "Deleted the  binary file");

$got = $repo->git_svn_diff(qw(-r 1:3));
cmp_diff($got, $expected, "Deletion combination");

$got = $repo->git_svn_diff(qw(-r 0:3));
$expected = <<DIFF;
DIFF
cmp_diff($got, $expected, "Empty diff");

exit;
