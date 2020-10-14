INTRODUCTION
============

Merginal aims to provide a nice interface for dealing with Git branches. It
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
 * Viewing git history for branches


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

To see a list of keymaps available in each Merginal buffer, press `?`.
