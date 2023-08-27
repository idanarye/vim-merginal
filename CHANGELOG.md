# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

## [2.2.4] - 2023-08-27
### Fixed
- `ds` now calls `:Ghdiffsplit`, since that's the new name of `:Gsdiffsplit`.

## [2.2.3] - 2022-10-29
### Fixed
- Remove a stray echo when generating help for the various Merginal buffers.

## [2.2.2] - 2022-10-05
### Fixed
- Replace `fugitive#repo()` usage with Fugitives standalone functions.

## [2.2.1] - 2021-11-26
### Fixed
- Use `FugitiveShellCommand` instead of `repo.git_command` (which is deprecated by Fugitive)
- Use `Git merge` instead of `Gmerge` (which is deprecated by Fugitive)

## [2.2.0] - 2020-12-06
### Added
- Support separate Meginal buffers on multiple tabs.
- Added merginal_remoteVisible variable to set remote branches to be viewed by default.
- Added a hotkey 'tr' to toggle remote branches in the view.

### Changed
- Calling `Merginal` or `MerginalToggle` when the merginal buffer is open but not in the main mode (branch list by default, or changes if in special Git status) will:
  - Jump to it, if the user is in another window.
  - Change it to the main mode, if the user is in it.

## [2.1.2] - 2020-01-29
### Fixed
- Made merginal commands global, not buffer-local, because Fugutive no longer fires the signals Merginal depended on.
- Changed `fugitive#detect` to `FugitiveDetect`.
- Made `pS` push with `--force-with-lease` instead of just `--force`. Yes, this is a fix. No this is not a breaking change. If this breaks your workflow then your workflow was broken to begin with.
- Made all the mappings `<nowait>`.

## [2.1.1] - 2019-09-06
### Added
- `g:merginal_logCommitCount` to allow limiting amount of commits displayed in history log.

### Fixed
- Fix `fileFullPath` bug.
- Correct argument order for merging.

## [2.1.0] - 2017-10-29
### Added
- NERDTree style keymaps for opening files.
- `g:merginal_windowWidth`/`g:merginal_windowSize` to control window size.
- `g:merginal_splitType` to control splitting (vertically/horizontally).

### Changed
- Use committer date instead of author date in `historyLog`.

### Fixed
- Use exception number instead of string.
- Fixed handling of uninitialized modules.
- Added missing merge commands to `mergeConflicts` buffer. This is considered a fix because we had it in v1.
- Fix Pushing when there are multiple remotes.
- Fix keymaps leaking between buffers.
- Fix command running for Vim8 with `:terminal` support.

## [2.0.2] - 2016-07-09
### Fixed
- Stop refresh() from changing other buffers.

## [2.0.1] - 2016-05-01
### Fixed
- Fixed filtering in history log.
- Added missing open-conflicted-file keymap. This is considered a fix because we had it in v1.

## [2.0.0] - 2016-04-09
### Added
- `?` to display keymap help in the various Merginal buffers.
- `&` to filter the entries in the various Merginal buffers.

### Changed
- [**BREAKING**?] Use filetypes instead of autocommands to set up the Merginal buffers.
- [**BREAKING**?] Moved to a basic module framework to organize buffer types.

### Fixed
- Fixed bug when calling `:MerginalToggle` from the merginal buffer.
- Fixed showing the current branch on checkout.
- Use `:terminal` for remote commands in Neovim. This is considered a fix, because without it you wouldn't be able to enter the git password in GUI Neovim.

## [1.6.0] - 2015-09-23
### Added
- Clos`mn` keymap for merging with `--no-ff`.
- Conflict-resolving mode for cherry-picking.

### Fixed
- Fixed a bug where failure to do an operation would mess up the Vim windows.

## [1.5.0] - 2015-02-14
### Added
- `q` keymap to close the merginal window.
- `pr` keymap for pull-rebase.
- `gl` keymap to open the history log for the branch under the cursor.
- Checking out commits from the log history buffer.
- Diffing against commits in the history log buffer.
- Opening the history log buffer from the rebase amend buffer.
- `<C-p>` and `<C-n>` to move between commits in history log.

### Changed
- Use echom instead of echo to have them in `:messages`

### Fixed
- Clear augroup (in case of reloads)

## [1.4.0] - 2014-09-19
### Added
- `pS` keymap for force pushing branches.
- A buffer type for `rebase-amend`.
- `rn` keymap for renaming branches.

## [1.3.0] - 2014-08-11
### Added
- Rebase functionality - (similar to merge functionality)
- `MerginalToggle` and `MerginalClose` commands.

### Changed
- Allow pushing/pulling/rebasing directly on remotes

### Fixed
- Fixed a bug where merges without conflicts open empty list.

## [1.2.0] - 2014-07-08
### Added
- `mf` keymap to run Fugitive's `:Gmerge`.
- `merginal#branchDetails`.
- `ct` and `cT` for tracking remote branches.
- `ps`, `pl` and `pf` to push, pull and fetch branches
- Branch diff functionality

### Changed
- Made the merginal buffer window have fixed size.
- Made `dd` be able to delete remote branches

### Fixed
- Set nonumber in merginal buffer.
- Fixed a bug where Merginal would change user buffers.

## [1.1.0] - 2014-06-06
### Changed
- Use autocmd for adding the keymaps.
- Use Fugitive's style of keymaps(`cc`=`C` etc.)

## [1.0.0] - 2014-06-04
### Added
- Branch list.
- Basic branch commands.
