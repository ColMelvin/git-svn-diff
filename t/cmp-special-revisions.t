#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 15;
use Test::Repo qw(cmp_ver get_svn_version);

my $before_1_7 = cmp_ver(get_svn_version(), '1.7') < 0;
my $before_1_8 = cmp_ver(get_svn_version(), '1.8') < 0;

my $repo = Temp::Repo->new();

$repo->svn_new_file("file", "contents\n");
$repo->svn_commit("Initial commit");

$repo->svn_new_file("other", "stuff\n");
$repo->svn_commit("Added an other file");
# Set BASE to r2 (Git-only)
$repo->git_run(qw(git checkout -q git-svn));

$repo->svn_overwrite_file("file", "updated\ncontents\n");
$repo->svn_overwrite_file("other", "stuffed\n");
$repo->svn_new_file("new", "file\n");
$repo->svn_commit("Revamp after BASE");

$repo->svn_overwrite_file("other", "stuff\nto\ndo");
$repo->svn_overwrite_file("new", "information\n");
$repo->svn_commit("Modified new and other");

# Set BASE to r2 (SVN-only)
$repo->svn_run(qw(svn update -r 2));

$repo->wc_set_file("file", "revised\ncontents\n");
$repo->wc_set_file("other", "Nothing special");

# Test with a BASE that is earlier than HEAD.
{
	test_repo($repo, [qw(-r BASE)], 1, undef, "BASE earlier than HEAD: Compare to BASE");
	test_repo($repo, [qw(-r COMMITTED)], 1, undef, "BASE earlier than HEAD: Compare to COMMITTED");
	local $TODO = "Issue #30" if $before_1_8;
	test_repo($repo, [qw(-r PREV)], 1, undef, "BASE earlier than HEAD: Compare to PREV");
}

# Clear working copy changes
$repo->svn_run(qw(svn revert -R .));
$repo->git_run(qw(git checkout -- .));

# Set BASE to r4
$repo->svn_run(qw(svn update));
$repo->git_run(qw(git checkout -q git-svn));

$repo->wc_set_file("file", "revised\ncontents\n");
$repo->wc_set_file("other", "Nothing special");

# Test with a BASE equivalent to HEAD.
{
	test_repo($repo, [qw(-r BASE)], 1, undef, "BASE at HEAD: Compare to BASE");
	test_repo($repo, [qw(-r COMMITTED)], 1, undef, "BASE at HEAD: Compare to COMMITTED");
	local $TODO = "Issue #30" if $before_1_8;
	test_repo($repo, [qw(-r PREV)], 1, undef, "BASE at HEAD: Compare to PREV");
}

# Test with a single file specified, with changes in the working copy.
{
	my @files = qw(file);
	test_repo($repo, [qw(-r BASE)], 1, \@files, "One file specified: Compare to BASE");
	local $TODO = "Issue #29" if $before_1_7;
	test_repo($repo, [qw(-r COMMITTED)], 0, \@files, "One file specified: Compare to COMMITTED");
	local $TODO = "Issue #25";
	test_repo($repo, [qw(-r PREV)], 0, \@files, "One file specified: Compare to PREV");
}

# Test with multiple files with changes in the working copy.
{
	my @files = qw(file other);
	test_repo($repo, [qw(-r BASE)], 1, \@files, "Multiple files specified: Compare to BASE");
	local $TODO = "Issue #29" if $before_1_7;
	test_repo($repo, [qw(-r COMMITTED)], 0, \@files, "Multiple files specified: Compare to COMMITTED");
	local $TODO = "Issue #20";
	test_repo($repo, [qw(-r PREV)], 0, \@files, "Multiple files specified: Compare to PREV");
}

# Test with multiple files where one is unchanged in the working copy.
{
	my @files = qw(file new);
	test_repo($repo, [qw(-r BASE)], 1, \@files, "Unchanged file specified: Compare to BASE");
	local $TODO = "Issue #29" if $before_1_7;
	test_repo($repo, [qw(-r COMMITTED)], 0, \@files, "Unchanged file specified: Compare to COMMITTED");
	local $TODO = "Issue #20";
	test_repo($repo, [qw(-r PREV)], 0, \@files, "Unchanged file specified: Compare to PREV");
}

exit;

sub test_repo {
	my ($repo, $args, $global_rev, $files, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [$global_rev ? '--global-revision' : '--no-global-revision'], files => $files, name => $message);
}
