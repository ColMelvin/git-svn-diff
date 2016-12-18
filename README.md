# Git-SVN-Diff

Enhancing git workflows in an SVN-entrenched environment

## Introduction

Git provides the **git-svn**(1) utility, which acts as a bidirectional bridge for interfacing a local git repository with a remote SVN repository.  This makes it possible to work on a project stored in SVN, which is popular in many corporate settings, using all the power of Git.  While this utility is mature, it notably lacks a tool to create diffs like SVN does (with revision information).

In most instances, the patch files produced by Git will work without issue.  Patching tools, like **patch**(1) itself, can work with any unified diff as it discards any extra annotations.  This explains why `git svn diff` is not a supported command; general tools have no problem handling any diff.  However, some very specific tools need a "properly" annotated diff: code review tools.

Many code review tools hook into the code repository to do their job.  Some may need a proper diff so they can push to SVN on approval.  Others may use the extra information to look up history, to provide more information to the reviewers.  Still others may be pedantic.  In these particular instances, the patch needs to be in the SVN-style, with all the appropriate annotations.  This tool solves that problem.

## Features

* Support for most options in **git-diff**(1)
* Support for common `svn diff` options
* In-line transformations; great for piping
* Configuration values to persist options
* Thorough acceptance test suite

## Limitations

Some of the more notable limitations include:
* The source commit MUST be checked-in to SVN
* SVN properties are not supported

Most shortcomings of git-svn-diff are inconsequential.  Check out the [issue tracker](https://github.com/ColMelvin/git-svn-diff/issues) for the full list.

## Documentation

Run `perldoc $(which git-svn-diff)` for details; `git-svn-diff --help` for a summary.

## See Also

Several simple transformation scripts use **sed**(1) to alter the format.  Check out http://mojodna.net/2009/02/24/my-work-git-workflow.html for an example.

## License and Copyright

Copyright (C) 2012-2016  Chris Lindee

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
