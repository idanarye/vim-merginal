INTRODUCTION
============

Merginal aims provide a nice inteface for dealing with Git branches.  It
offers interactive TUI for:

 * Viewing the list of branches
 * Checking out branches from that list
 * Creating new branches
 * Deleting branches
 * Merging branches
 * Solving merge conflicts
 * Interacting with remotes(pulling, pushing, fetching, tracking)
 * Diffing against other branches


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


THE BRANCH LIST
===============

The branch list shows a list of branches. While in that list, you can use the
following keymaps to interact with the branches:

* `R`      Refresh the buffer list.
* `C`/`cc` Checkout the branch under the cursor.
* `A`/`aa` Create a new branch from the currently checked out branch. You'll be
           prompted to enter a name for the new branch.
* `D`/`dd` Delete the branch under the cursor.
* `M`/`mm` Merge the branch under the cursor into the currently checked out
           branch. If there are merge conflicts, the merge conflicts
           buffer will open in place of the branch list buffer.
* `mf`     Merge the branch under the cursor into the currently checked out branch
           using Fugitive's `:Gmerge` command.
* `ps`     Prompt to choose a remote to push the branch under the cursor.
* `pl`     Prompt to choose a remote to pull the branch under the cursor.
* `pf`     Prompt to choose a remote to fetch the branch under the cursor.
* `gd`     Diff against the branch under the cursor.

Run `:help merginal-branch-list` for more info.


MERGE CONFLICTS
===============

The merge conflicts buffer is used to solve merge conflicts. It shows all the
files that have merge conflicts and offers the following keymaps:

* `R`      Refresh the merge conflicts list.
* `<Cr>`   Open the conflicted file under the cursor.
* `A`/`aa` Add the conflicted file under the cursor to the staging area. If that
           was the last conflicted file, the merge conflicts buffer will close and
           Fugitive's status window will open.

DIFF FILES
==========
The diff files buffer is used to diff against another branch. It displays all
the differences between the currently checked out branch and the branch it was
opened against, and offerts the following keymaps:

* `R`      Refresh the diff files list.
* `<Cr>`   Open the file under the cursor(if it exists in the currently checked
           out branch).
* `ds`     Split-diff against the file under the cursor(if it exists in the other
           branch)
* `ds`     VSplit-diff against the file under the cursor(if it exists in the other
           branch)
* `co`     Check out the file under the cursor(if it exists in the other branch)
           into the current branch.
