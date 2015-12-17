package Test::Repo;

use strict;
use warnings;

require Test::Builder;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	test_diff
	get_diff
	cmp_diff
	get_svn_version
	cmp_ver
);

my $is_eq;
my @extra_git_args;

INIT {
	$is_eq ||= eval { require Test::Differences; return \&Test::Differences::eq_or_diff };
	$is_eq ||= eval { require Test::More; return \&Test::More::is };

	push @extra_git_args, '--show-nonexistent' if cmp_ver(get_svn_version(), '1.9') >= 0;
}

sub get_svn_version {
	my $str = qx{svn --version};
	my ($svn_ver) = $str =~ m/\Asvn, version (\d+(?:\.\d+)*)\b/ or die "Cannot determine SVN version:\n$str";
	return $svn_ver;
}

sub cmp_ver {
	my ($v1, $v2) = @_;

	my @s1 = split m/\./, $v1;
	my @s2 = split m/\./, $v2;

	while (@s1 && @s2) {
		my $cmp = shift @s1 <=> shift @s2;
		return $cmp if $cmp;
	}
	return @s1 <=> @s2;
}

sub get_diff {
	my ($repo, %opts) = @_;
	my @svn_args = ( @{ $opts{args} || [] }, @{ $opts{svn_args} || [] } );
	my @git_args = ( @{ $opts{args} || [] }, @{ $opts{git_args} || [] }, @extra_git_args );

	if ($opts{files}) {
		push @svn_args, "--", @{ $opts{files} };
		push @git_args, "--", @{ $opts{files} };
	}

	my $expected = $repo->svn_diff(@svn_args);
	my $orderfile = $repo->create_git_orderfile($expected);

	my $got = $repo->git_svn_diff("-O$orderfile", @git_args);

	return ($got, $expected);
}

sub cmp_diff {
	my ($got, $expected, $name) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return &$is_eq($got, $expected, $name);
}

sub test_diff {
	my ($repo, %opts) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($got, $expected) = get_diff($repo, %opts);
	return cmp_diff($got, $expected, $opts{name});
}

1;
