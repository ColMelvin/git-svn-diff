#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 29;
use Test::Repo qw(get_svn_version cmp_ver);

my $svn_version = get_svn_version();

my $repo = Temp::Repo->new();

$repo->svn_new_file("A", "Initial\ncontents\n");
$repo->svn_commit("Initial commit");

$repo->svn_overwrite_file("A", "Updated\ncontents\n");
$repo->svn_new_file("B", "File with exactly 1 commit\n");
$repo->svn_new_file("C", "File with exactly 2 commits\n");
$repo->svn_commit("Mass addition of files");

$repo->svn_overwrite_file("A", "Updated\ncontents\nonce\nagain\n");
$repo->svn_commit("Modified A one last time");

$repo->svn_overwrite_file("C", "Second (and last) modification\n");
$repo->svn_new_file("D", "Nothing to see here\n");
$repo->svn_commit("Modified C & D (for the last time)");

$repo->git_run(qw(git checkout -q git-svn));

diag("Run tests without working copy changes");
{
	local $TODO = "Issue #27";
	test_repo($repo, [qw(-r COMMITTED)], 1, undef, "-r COMMITTED: No file specified");
}

test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A' ], "-c COMMITTED: Check file changed before BASE");
SKIP: {
	skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
	local $TODO = "Issue #26" if cmp_ver($svn_version, "1.8") < 0;
	test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'B' ], "-c COMMITTED: Check file changed only once (not in BASE)");
}
test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'C' ], "-c COMMITTED: Check file changed in BASE");
SKIP: {
	skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
	local $TODO = "Issue #26" if cmp_ver($svn_version, "1.8") < 0;
	test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'D' ], "-c COMMITTED: Check file added in BASE");
}
{
	local $TODO = "Issue #20";
	SKIP: {
		skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
		test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A', 'B' ], "-c COMMITTED: Check files last edited before BASE");
	}
	test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A', 'C' ], "-c COMMITTED: Check 2 files: 1 edited in BASE, one before");
	SKIP: {
		skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
		test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A', 'D' ], "-c COMMITTED: Check 2 files: 1 added in BASE, one before");
	}
}

# Note: We can't do -r PREV:BASE with files that have exactly one commit.
{
	local $TODO = "Issue #21";
	test_repo($repo, [qw(-r PREV:BASE)], 1, [ 'A' ], "-r PREV: Check file changed before BASE");
	test_repo($repo, [qw(-r PREV:BASE)], 1, [ 'C' ], "-r PREV: Check file changed in BASE");
	$TODO = "Issues #20 & #21";
	test_repo($repo, [qw(-r PREV:BASE)], 1, [ 'A', 'C' ], "-r PREV: Check 2 files: 1 edited in BASE, one before");
}

# Add working copy changes for further tests.
$repo->wc_set_file("A", "Updated\nfile\n");
$repo->wc_set_file("B", "File with 1 commit and 1 WC change");
$repo->wc_set_file("C", "Second (and last) modification\nto the file in the repository\n");
$repo->wc_set_file("E", "Hey, a new file appears\n");

diag("Run tests with working copy changes");
{
	local $TODO = "Issue #27";
	test_repo($repo, [qw(-r COMMITTED)], 1, undef, "-r COMMITTED: No file specified");
}

test_repo($repo, [qw(-r COMMITTED)], 0, [ 'A' ], "-r COMMITTED: Check file changed before BASE");
test_repo($repo, [qw(-r COMMITTED)], 0, [ 'B' ], "-r COMMITTED: Check file changed only once (not in BASE)");
test_repo($repo, [qw(-r COMMITTED)], 0, [ 'C' ], "-r COMMITTED: Check file changed in BASE");
test_repo($repo, [qw(-r COMMITTED)], 0, [ 'D' ], "-r COMMITTED: Check file added in BASE");
test_repo($repo, [qw(-r COMMITTED)], 0, [ 'A', 'B' ], "-r COMMITTED: Check files last edited before BASE");
test_repo($repo, [qw(-r COMMITTED)], 0, [ 'A', 'C' ], "-r COMMITTED: Check 2 files: 1 edited in BASE, one before");
test_repo($repo, [qw(-r COMMITTED)], 0, [ 'A', 'D' ], "-r COMMITTED: Check 2 files: 1 added in BASE, one before");

test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A' ], "-c COMMITTED: Check file changed before BASE");
SKIP: {
	skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
	local $TODO = "Issue #26" if cmp_ver($svn_version, "1.8") < 0;
	test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'B' ], "-c COMMITTED: Check file changed only once (not in BASE)");
}
test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'C' ], "-c COMMITTED: Check file changed in BASE");
SKIP: {
	skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
	local $TODO = "Issue #26" if cmp_ver($svn_version, "1.8") < 0;
	test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'D' ], "-c COMMITTED: Check file added in BASE");
}
{
	local $TODO = "Issue #20";
	SKIP: {
		skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
		test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A', 'B' ], "-c COMMITTED: Check files last edited before BASE");
	}
	test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A', 'C' ], "-c COMMITTED: Check 2 files: 1 edited in BASE, one before");
	SKIP: {
		skip "File must exist in repository for 2 or more commits", 1 if cmp_ver($svn_version, '1.7') < 0;
		test_repo($repo, [qw(-r PREV:COMMITTED)], 1, [ 'A', 'D' ], "-c COMMITTED: Check 2 files: 1 added in BASE, one before");
	}
}

# Note: We can't do -r PREV with files that have exactly one commit.
test_repo($repo, [qw(-r PREV)], 1, [ 'A' ], "-r PREV: Check file changed before BASE");
test_repo($repo, [qw(-r PREV)], 1, [ 'C' ], "-r PREV: Check file changed in BASE");
{
	local $TODO = "Issue #20";
	test_repo($repo, [qw(-r PREV)], 1, [ 'A', 'C' ], "-r PREV: Check 2 files: 1 edited in BASE, one before");
}

exit;

sub test_repo {
	my ($repo, $args, $global_rev, $files, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [$global_rev ? '--global-revision' : '--no-global-revision'], files => $files, name => $message);
}
