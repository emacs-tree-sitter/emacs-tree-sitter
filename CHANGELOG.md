# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
- Added support for parsing and highlighting a single region, to enable `jupyter-repl` [integration](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/78).

## [0.18.0] - 2022-02-12
- Added APIs to traverse the syntax tree: `tsc-traverse-do`, `tsc-traverse-mapc`, `tsc-traverse-iter`. The traversal is depth-first pre-order.
- Improved syntax tree rendering's performance in `tree-sitter-debug`.
- Added optional params `props` and `output` to `tsc-current-node`, which allows retrieving node properties, instead of the node object itself. This enables performance optimizations in uses cases that deal with a large number of nodes.

## [0.17.0] - 2022-01-29
- Added customization option `tsc-dyn-get-from`, which is a list of sources to get the dynamic module `tsc-dyn` from. Its default value is `(:github :compilation)`.
- Made `tree-sitter-hl`'s region-fontification function fall back to the underlying non-tree-sitter function when called outside of `tree-sitter-hl-mode`. This fixes an issue where `jupyter-repl-mode`'s [input cells are not highlighted](https://github.com/nnicandro/emacs-jupyter/issues/363).
- Updated `tsc-dyn-get` to download platform-specific binaries (mainly for Apple Silicon).

## [0.16.1] - 2021-12-11
- Modified CI pipelines to publish additional pre-built dynamic modules. Their filenames include the platform they are built for. The files without platform in name will eventually be deprecated.
  + `tsc-dyn.x86_64-apple-darwin.dylib` (same as `tsc-dyn.dylib`)
  + `tsc-dyn.x86_64-unknown-linux-gnu.so` (same as `tsc-dyn.so`)
  + `tsc-dyn.x86_64-pc-windows-msvc.dll` (same as `tsc-dyn.dll`)
  + `tsc-dyn.aarch64-apple-darwin.dylib` (new, for Apple Silicon)

## [0.16.0] - 2021-12-08
- Upgraded `tree-sitter` crate to 0.20.0, which:
  + Changed the semantics of range-restricted query to report matches that intersect the range, instead of only fully-contained matches. See [tree-sitter#1130](https://github.com/tree-sitter/tree-sitter/pull/1130).
  + Fixed [an issue](https://github.com/tree-sitter/tree-sitter/pull/1372#issuecomment-924958513) where multiple patterns with the same capture names can result in the first capture being omitted.
- Improved performance:
  + Disabled query-region extension. Added a flag to turn it back on: `tree-sitter-hl-enable-query-region-extension`.
  + Increased default chunk size for parsing from 1024 to 4096.

## [0.15.2] - 2021-09-12
- Reduced GC pressure by not making the text property `face` a list if there is only one face.
- Recast `tree-sitter-node-at-point` as more general `tree-sitter-node-at-pos`, taking optional POS argument.
- Made `tree-sitter-node-at-pos` accept special node-type arguments `:named` and `:anonymous`.

## [0.15.1] - 2021-03-20
- Fixed some invalid query patterns [causing SIGABRT](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/125), by upgrading `tree-sitter` crate.
- Used keywords to represent auxiliary (invisible) node types. For example: `:end`, `:_expression`.

## [0.15.0] - 2021-03-15
- Upgraded `tree-sitter` crate to 0.19.3, which:
  + Added [negated-field query patterns](https://github.com/tree-sitter/tree-sitter/pull/983).
  + Fixed some bugs, mostly query-related.
  + Is required to support newer versions of the language grammars.
  + Raised the minimum and maximum supported language ABI versions to 13. Older versions of the language bundle `tree-sitter-langs` (before 0.10.0) will not be loaded.

## [0.14.0] - 2021-03-10
- Added ABI compatibility checks when loading a language object from a dynamic library.
- Made `tsc-make-query` signal concrete error symbols, instead of `rust-panic`.

## [0.13.1] - 2021-01-16
- Used static linking for C runtime on Windows, to avoid having to install VC++ redistributable package.

## [0.13.0] - 2020-12-29
- Upgraded `emacs` crate to [0.15.0](https://github.com/ubolonton/emacs-module-rs/releases/tag/0.15.0) to improve performance on Emacs 27+.
- Fixed the [highlighting error when exporting org as html](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/74), by removing the hack that allows `tree-sitter-hl` to work without (a major mode) setting up `font-lock-defaults`.

## [0.12.2] - 2020-12-15
- Added warning after upgrading `tsc` if it requires a new version of the dynamic module `tsc-dyn`, but an older version was already loaded.
- Improved language loading mechanism's tolerance of hyphens in language names.

## [0.12.1] - 2020-11-04
- Fixed incorrect parsing when after-change's start position is not the same as before-change's start position. For example, this happens when calling `upcase-region` on a region whose first character is already upcased.
- Upgraded `emacs` crate to [0.14.1](https://github.com/ubolonton/emacs-module-rs/releases/tag/0.14.1) to fix the [compilation error on Rust 1.47](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/62).
- Upgraded `tree-sitter` crate to 0.17.1 to [fix](https://github.com/tree-sitter/tree-sitter/issues/790) [handling of repeated field names in queries](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/67).

## [0.12.0] - 2020-10-13
- Moved the core APIs from `tree-sitter-core.el` into their own package `tsc`, to prepare for [distribution through MELPA](https://github.com/melpa/melpa/pull/7112). Also changed their prefix from `ts-` to `tsc-`, to avoid [conflict with `ts.el`](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/35).

## [0.11.1] - 2020-10-03
- Made `tree-sitter-hl-mode` a "no-op" when `tree-sitter-hl-default-patterns` is nil.

## [0.11.0] - 2020-09-26
- Upgraded `tree-sitter` crate to [fix](https://github.com/tree-sitter/tree-sitter/pull/644) an issue where [query captures miss some nodes](https://github.com/tree-sitter/tree-sitter/issues/659). This also added a check for definitely-invalid patterns when creating a query.

## [0.10.0] - 2020-08-01
- Used keywords instead of strings for field names.
  + Replaced `ts-field-name-for-id`, `ts-field-id-for-name` with `ts-lang-field`, `ts-lang-field-id`.
  + Replaced `ts-current-field-name` with `ts-current-field`.
  + Replaced `ts-get-child-by-field-name` with `ts-get-child-by-field`.
- Used symbols for named node types.
  + Replaced `ts-type-name-for-id` with `ts-lang-node-type`.
  + Added `ts-lang-node-type-id`.
  + Changed the return type of `ts-node-type`.
- Renamed `ts-type-named-p` to `ts-lang-node-type-named-p`.
- Added optional param `NODE-TYPE` to `tree-sitter-node-at-point`.
- Upgraded `tree-sitter` crate to get support for `.not-match?` predicate.

## [0.9.2] - 2020-07-20
- Upgraded `tree-sitter` crate to add `.` as a valid start of predicates, in addition to `#`.

## [0.9.1] - 2020-07-19
- Upgraded `tree-sitter` crate to fix [incorrect capture handling](https://github.com/tree-sitter/tree-sitter/issues/685) when querying with range restriction.

## [0.9.0] - 2020-07-18
- Changed `tree-sitter-hl-add-patterns` to support language-specific patterns, in addition to buffer-local patterns.

## [0.8.3] - 2020-07-12
- Fixed incorrect highlighting when region-to-highlight's boundaries cut query patterns in halves.

## [0.8.2] - 2020-06-30
- Upgraded `tree-sitter` crate to [fix](https://github.com/tree-sitter/tree-sitter/pull/661) handling of alternations under field names.

## [0.8.1] - 2020-06-28
- Added customization option `tree-sitter-hl-use-font-lock-keywords`, allowing `tree-sitter-hl-mode` to work with minor modes that use `font-lock-add-keywords`.

## [0.8.0] - 2020-06-07
- Upgraded `tree-sitter` to 0.16.1. This significantly improved the expressiveness and power of tree queries.
- Made `tree-sitter-hl-mode` work without a major mode.
- Add more highlighting faces to `tree-sitter-hl`.
- Made `tree-sitter-core` automatically download `tree-sitter-dyn` binary when first compiled/loaded.
- Added [documentation](https://emacs-tree-sitter.github.io/).

## [0.7.0] - 2020-05-02
- Added `global-tree-sitter-mode`.
- Added library `tree-sitter-hl`, which provides query-based syntax highlighting by overriding certain parts of `font-lock`.
- Reworked query APIs for performance and clarity, most notably `ts-make-query`, `ts-query-matches`, `ts-query-captures`.
- Fixed incorrect parsing caused by misunderstandings of Emacs's clumsy change tracking machinery.

## [0.6.0] - 2020-04-11
- Renamed `ts-parse` into `ts-parse-chunks`, to avoid [conflict with `ts.el`](https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/35).
- Added library `tree-sitter-query`, which enables interactively building queries.

## [0.5.0] - 2020-03-17
- Added functions `ts-node-position-range`, `ts-node-eq`.
- Added function `tree-sitter-node-at-point`.
- Added macro `tree-sitter-save-excursion`, which is useful for code formatting operations.
- Added library `tree-sitter-extras`, for extra functionalities built on top of `tree-sitter-mode`.
- Upgraded `tree-sitter` to 0.6.3. This fixed `ts-type-name-for-id` and `ts-field-name-for-id` crashing on out-of-bounds IDs.
- Fixed `ts-reset-cursor` always signaling "already mutable borrowed" error.

## [0.4.0] - 2020-03-01

- Replaced functions `ts-require-language` and `ts-load-language` with `tree-sitter-require` and `tree-sitter-load`.
- Published pre-compiled `tree-sitter` through a custom ELPA.
- Published the grammar bundle `tree-sitter-langs` as a separate package.

## [0.3.0] - 2020-02-21
- Used Emacs's 1-based byte positions and line numbers instead of 0-based byte offsets and row coordinates.
- Used cons cells instead of 2-element vectors to represent tree-sitter points and query matches/captures.

## [0.2.0] - 2020-02-02
- Upgraded `tree-sitter` to 0.6.0.
- Added library `tree-sitter-cli`.
- Added library `tree-sitter-langs` (utilities to download pre-compiled modules and grammars).

## [0.1.0] - 2020-01-27
Initial release

[Unreleased]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.18.0...HEAD
[0.18.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.17.0...0.18.0
[0.17.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.16.1...0.17.0
[0.16.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.16.0...0.16.1
[0.16.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.15.2...0.16.0
[0.15.2]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.15.1...0.15.2
[0.15.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.15.0...0.15.1
[0.15.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.14.0...0.15.0
[0.14.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.13.1...0.14.0
[0.13.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.13.0...0.13.1
[0.13.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.12.2...0.13.0
[0.12.2]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.12.1...0.12.2
[0.12.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.12.0...0.12.1
[0.12.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.11.1...0.12.0
[0.11.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.11.0...0.11.1
[0.11.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.10.0...0.11.0
[0.10.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.9.2...0.10.0
[0.9.2]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.9.1...0.9.2
[0.9.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.8.3...0.9.0
[0.8.3]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.8.2...0.8.3
[0.8.2]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.8.1...0.8.2
[0.8.1]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/emacs-tree-sitter/elisp-tree-sitter/compare/0.1.0...0.2.0
