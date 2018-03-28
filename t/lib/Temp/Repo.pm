package Temp::Repo;

use strict;
use warnings;

use FindBin;
use File::chdir;
use File::Path;
use File::Spec;
use File::Spec::Unix;
use File::Temp;
use IPC::Run;

my $diff_bin = "$FindBin::Bin/../bin/git-svn-diff";

sub new {
	my ($class, %opts) = @_;

	# Can't use an object interface because of old Perls.
	my $dir = File::Temp::tempdir(TMPDIR => 1, CLEANUP => 1);

	my $self = { dir => $dir };
	bless $self, $class;

	$self->_initialize(%opts);
	return $self;
}

sub _initialize {
	my ($self, %opts) = @_;

	my $dir = $self->{dir};
	__run_in($dir, qw(svnadmin create repo));

	my $base = File::Spec::Unix->canonpath($dir);
	if ($^O eq "MSWin32") {
		$base =~ s{\\}{/}g;
		$base = "/$base";
	}

	my $repo = "file://$base/repo";
	$self->{repo} = $repo;

	# Setup the standard layout, if requested.
	my @git_opts;
	if ($opts{stdlayout}) {
		system qw(svn mkdir -m stdlayout), "$repo/trunk", "$repo/branches", "$repo/tags";
		push @git_opts, "-s", "--prefix=origin/";
	}

	# Clone SVN & Git repositories.
	__run_in($dir, qw(svn checkout -q), $repo, "svn");
	$repo =~ s{^(file:///\w):}{$1} if $^O eq "MSWin32";	# Workaround for https://github.com/git-for-windows/git/issues/1593
	__run_in($dir, qw(git svn init), @git_opts, $repo, "git");
}

sub get_svn_wc {
	my ($self) = @_;
	return File::Spec->catdir($self->{dir}, 'svn');
}

sub get_git_wc {
	my ($self) = @_;
	return File::Spec->catdir($self->{dir}, 'git');
}

sub svn_run {
	my ($self, @args) = @_;
	__run_in($self->get_svn_wc(), @args);
}

sub git_run {
	my ($self, @args) = @_;
	__run_in($self->get_git_wc(), @args);
}

sub svn_new_dir {
	my ($self, $path) = @_;

	my $dir = File::Spec->catdir($self->get_svn_wc(), $path);
	my @created = File::Path::mkpath($dir);
	foreach my $p (@created) {
		$self->svn_run(qw(svn add), $p);
	}

	return $dir;
}

sub svn_new_file {
	my ($self, $path, $contents) = @_;

	my $file = $self->svn_overwrite_file($path, $contents);
	$self->svn_run(qw(svn add), $file);

	return $file;
}

sub svn_overwrite_file {
	my ($self, $path, $contents) = @_;

	my $file = File::Spec->catfile($self->get_svn_wc(), $path);
	open my $fh, '>', $file or die "Cannot open file “$file”: $!";
	print {$fh} $contents;
	close $fh or warn "Cannot close file “$file”: $!";

	return $file;
}

sub svn_set_symlink {
	my ($self, $target, $path) = @_;

	my $file = File::Spec->catfile($self->get_svn_wc(), $path);
	unlink $file or die "Cannot remove file “$file”: $!" if lstat $file;
	symlink $target, $file or die "Cannot create symlink “$file” -> “$target”: $!";

	return $file;
}

sub svn_remove_file {
	my ($self, $path) = @_;

	my $file = File::Spec->catfile($self->get_svn_wc(), $path);
	$self->svn_run(qw(svn rm), $file);

	return $file;
}

sub svn_commit {
	my ($self, $message) = @_;
	die "No message" if !$message;
	$self->svn_run(qw(svn commit -m), $message);
	__capture_cmd($self->get_git_wc(), qw(git svn fetch -q));
	return;
}

sub wc_set_file {
	my ($self, $path, $contents) = @_;

	# Do SVN's working copy
	$self->svn_overwrite_file($path, $contents);

	# Then do Git's
	my $file = File::Spec->catfile($self->get_git_wc(), $path);
	open my $fh, '>', $file or die "Cannot open file “$file”: $!";
	print {$fh} $contents;
	close $fh or warn "Cannot close file “$file”: $!";

	return;
}

sub svn_diff {
	my ($self, @args) = @_;
	my ($out, $err) = __capture_cmd($self->get_svn_wc(), qw(svn diff), @args);
	warn $err if $err;
	return $out;
}

sub git_svn_diff {
	my ($self, @args) = @_;
	my ($out, $err) = __capture_cmd($self->get_git_wc(), $^X, $diff_bin, @args);
	warn $err if $err;
	return $out;
}

sub create_git_orderfile {
	my ($self, $svn_diff) = @_;

	my @order = map { quotemeta } $svn_diff =~ m/^Index: (.*)$/gm;

	my $file = File::Spec->catfile($self->{dir}, "orderfile");
	open my $fh, '>', $file or die "Cannot open file “$file”: $!";
	binmode $fh or die "Cannot set binmode: $!";	# Needed for Git on Windows
	print {$fh} join "\n", @order, '';
	close $fh or warn "Cannot close file “$file”: $!";

	return $file;
}

sub __run_in {
	my ($dir, @args) = @_;
	local $CWD = $dir;
	system @args;
}

sub __capture_cmd {
	my ($dir, @args) = @_;

	my ($out, $err);
	local $CWD = $dir;
	IPC::Run::run \@args, \'', \$out, \$err or die "Command terminiated with non-zero status: $?\nSTDERR:\n$err";
	return $out, $err;
}

1;
