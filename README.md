INTRODUCTION
============

Merginal aims provide a nice inteface for dealing with Git branches.  It
offers interactive TUI for:

 * Viewing the list of branches
 * Checking out branches from that list
 * Creating new branches
 * Deleting branches
 * Merging branches
 * Rebasing branches
 * Solving merge conflicts
 * Interacting with remotes(pulling, pushing, fetching, tracking)
 * Diffing against other branches
 * Renaming branches


REQUIREMENTS
============

Merginal is based on Fugitive, so it requires Fugitive. If you don't have it
already you can get it from https://github.com/tpope/vim-fugitive

It should go without saying that you need Git.

Under Windows, vimproc is an optional requirement. Merginal will work without
it, but it'll pop an ugly console window every time it needs to run a Git
command. You can get vimproc from https://github.com/Shougo/vimproc.vim


USAGE
=====

To use Merginal you need to know but one command: `:Merginal`. It'll open the
branch list buffer, unless the repository is in merge mode then
it'll open the merge conflicts buffer.

Like Fugitive's commands, `:Merginal` is native to the buffer, and will only
work in buffers that are parts of Git repositories.

You can also toggle the buffer with `:MerginalToggle` or close it with
`:MerginalClose`.


THE BRANCH LIST
===============

The branch list shows a list of branches. While in that list, you can use the
following keymaps to interact with the branches:

* `q`      Close the branch list.
* `R`      Refresh the branch list.
* `C`/`cc` Checkout the branch under the cursor.
* `A`/`aa` Create a new branch from the currently checked out branch. You'll be
           prompted to enter a name for the new branch.
* `D`/`dd` Delete the branch under the cursor.
* `M`/`mm` Merge the branch under the cursor into the currently checked out
           branch. If there are merge conflicts, the merge conflicts
           buffer will open in place of the branch list buffer.
* `mf`     Merge the branch under the cursor into the currently checked out branch
           using Fugitive's `:Gmerge` command.
* `rb`     Rebase the currently checked out branch against the branch under the
           cursor. If there are rebase conflicts, the rebase conflicts buffer will open in place of
           the branch list buffer.
* `ps`     Prompt to choose a remote to push the branch under the cursor.
* `pS`     Prompt to choose a remote to force push the branch under the cursor.
* `pl`     Prompt to choose a remote to pull the branch under the cursor.
* `pr`     Prompt to choose a remote to pull-rebase the branch under the cursor.
* `pf`     Prompt to choose a remote to fetch the branch under the cursor.
* `gd`     Diff against the branch under the cursor.
* `rn`     Prompt to rename the branch under the cursor.

Run `:help merginal-branch-list` for more info.


MERGE CONFLICTS
===============

The merge conflicts buffer is used to solve merge conflicts. It shows all the
files that have merge conflicts and offers the following keymaps:

* `q`      Close the merge conflicts list.
* `R`      Refresh the merge conflicts list.
* `<Cr>`   Open the conflicted file under the cursor.
* `A`/`aa` Add the conflicted file under the cursor to the staging area. If that
           was the last conflicted file, the merge conflicts buffer will close and
           Fugitive's status window will open.


REBASE CONFLICTS
================

The rebase conflicts buffer is used to solve rebase conflicts. It shows the
currently applied commit message and all the files that have rebase conflicts,
and offers the following keymaps:

* `q`      Close the rebase conflicts list.
* `R`      Refresh the rebase conflicts list.
* `<Cr>`   Open the conflicted file under the cursor.
* `aa`     Add the conflicted file under the cursor to the staging area. If
           that was the last conflicted file, prompt the user to continue to
           the next patch.
* `A`      Same as aa.
* `ra`     Abort the rebase.
* `rc`     Continue to the next patch.
* `rs`     Skip the current patch.


REBASE AMEND
================

The rebase amend buffer is shown when you amend a patch during a rebase. It
shows the amended commit's shortened hash and commit message. Additionally, it
shows all the branches so you can diff against them. If offers the following
keymaps:

* `q`      Close the rebase amend buffer.
* `R`      Refresh the rebase amend buffer.
* `gd`     Diff against the branch under the cursor.
* `ra`     Abort the rebase
* `rc`     Continue to the next patch.
* `rs`     Skip the current patch.


DIFF FILES
==========
The diff files buffer is used to diff against another branch. It displays all
the differences between the currently checked out branch and the branch it was
opened against, and offers the following keymaps:

* `q`      Close the diff files list.
* `R`      Refresh the diff files list.
* `<Cr>`   Open the file under the cursor (if it exists in the currently checked
           out branch).
* `ds`     Split-diff against the file under the cursor (if it exists in the other
           branch).
* `dv`     VSplit-diff against the file under the cursor (if it exists in the other
           branch).
* `co`     Check out the file under the cursor (if it exists in the other branch)
           into the current branch.
