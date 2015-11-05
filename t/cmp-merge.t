#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 1;
use Test::Repo qw(get_diff cmp_diff get_svn_version cmp_ver);

my $repo = Temp::Repo->new(stdlayout => 1);

my @extra_svn_args;
push @extra_svn_args, '--ignore-ancestry' if cmp_ver(get_svn_version(), '1.7') >= 0;
push @extra_svn_args, '--force' if cmp_ver(get_svn_version(), '1.5') >= 0;

$repo->svn_run(qw(svn switch), @extra_svn_args, svn_branch($repo, "trunk"));
$repo->svn_new_file("script", <<SCRIPT);
#!$^X

use strict;

use Getopt::Long;

GetOptions(
	help => sub { print "No help for you\\n"; exit },
);

print STDERR "Not yet implemented\\n";
exit 1;
SCRIPT
$repo->svn_commit("Initial commit");
$repo->svn_run(qw(svn copy), svn_branch($repo, "trunk"), svn_branch($repo, "FEATURE"), "-m", "Branch for feature");

$repo->svn_overwrite_file("script", <<SCRIPT);
#!$^X

use strict;
use warnings;

use Getopt::Long;

GetOptions(
	help => sub { print "No help for you\\n"; exit },
);

print STDERR "Not yet implemented\\n";
exit 1;
SCRIPT
$repo->svn_commit("Enable Perl warnings");

$repo->svn_run(qw(svn switch), svn_branch($repo, "FEATURE"));
$repo->svn_overwrite_file("script", <<SCRIPT);
#!$^X

use strict;

use Getopt::Long;

GetOptions(
	help => sub { print "No help for you\\n"; exit },
);

my \$exit = \$ARGV[0];
die "Invalid exit code: \$exit" if \$exit =~ m/\\D/ || \$exit < 0 || \$exit > 255;
exit \$exit;
SCRIPT
$repo->svn_commit("Add functionality");

$repo->svn_run(qw(svn switch), svn_branch($repo, "trunk"));
$repo->svn_run(qw(svn merge), svn_branch($repo, "FEATURE"));
$repo->svn_commit("Merge in feature");

$repo->git_run(qw(git checkout -q origin/trunk));

$TODO = "Issue #25";
test_repo($repo, [qw(-c 6)], "Compare clean merge");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	my ($got, $expected) = get_diff($repo, git_args => ['--no-show-in-function'], args => $args);

	my $problem = <<PROB;
Index: .
===================================================================
--- .\t(revision 5)
+++ .\t(revision 6)

Property changes on: .
___________________________________________________________________
Added: svn:mergeinfo
## -0,0 +0,1 ##
   Merged /branches/FEATURE:r3-5
PROB

	# Until svn:mime-type is supported, this test will fail.
	my $copy = $expected;
	local $TODO = "Issue #24" if $copy =~ s/^\Q$problem\E\z//m && $copy eq $got;

	cmp_diff($got, $expected, $message);
}

sub svn_branch {
	my ($repo, $branch) = @_;
	return "$repo->{repo}/$branch" if $branch eq "trunk";
	return "$repo->{repo}/branches/$branch";
}
