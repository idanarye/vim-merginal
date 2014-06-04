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
* `C`      Checkout the branch under the cursor.
* `A`      Create a new branch from the currently checked out branch. You'll be
           prompted to enter a name for the new branch.
* `D`      Delete the branch under the cursor.
* `M`      Merge the branch under the cursor into the currently checked out
           branch. If there are merge conflicts, the merge conflicts
           buffer will open in place of the branch list buffer.


MERGE CONFLICTS
===============

The merge conflicts buffer is used to solve merge conflicts. It shows all the
files that have merge conflicts and offers the following keymaps:

* `R`      Refresh the merge conflicts list.
* `<Cr>`   Open the conflicted file under the cursor.
* `A`      Add the conflicted file under the cursor to the staging area. If that
           was the last conflicted file, the merge conflicts buffer will close and
           Fugitive's status window will open.
