#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use File::chdir;

use Test::More tests => 2;
use Test::Repo;

{
	package Temp::Repo::Clone;

	use File::Spec;
	use Temp::Repo;

	our @ISA = qw(Temp::Repo);

	sub clone {
		my ($self) = @_;

		my $src = $self->SUPER::get_git_wc();
		my $dst = $self->{clone} = File::Spec->catdir($self->{dir}, 'clone');
		system qw(git clone -nq), $src, $dst;
		$self->git_run(qw(git checkout -q origin/master));
	}

	sub get_git_wc {
		my ($self) = @_;
		return $self->{clone} || $self->SUPER::get_git_wc();
	}
}

my $repo = Temp::Repo::Clone->new();

$repo->svn_new_file("file", "contents\n");
$repo->svn_commit("Initial commit");

$repo->svn_overwrite_file("file", "Contents\n");
$repo->svn_commit("Modification commit");
$repo->git_run(qw(git merge --ff-only -q git-svn));

$repo->clone();

$repo->wc_set_file("file", "Changed\nContents\n");
$repo->git_run(qw(git add -u));
$repo->git_run(qw(git commit -q -m), "Git-only change");

Test::Repo::test_diff($repo, name => "Diff with BASE");

my $diff_bin = "$FindBin::Bin/../bin/git-svn-diff";
my $dir = $repo->get_git_wc();

my $got;
{
	local $CWD = $dir;
	$got = qx{"$^X" "$diff_bin" --relative-repo 2>&1};
}
my $expected = <<ERR;
svn info: command returned error: 1
ERR
like($got, qr/^$expected\z/m, "Repository Root unknown");

exit;
