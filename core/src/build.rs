use std::path::{Path, PathBuf};
use tree_sitter_cli::generate;

use emacs::{defun, Result, Value};

const DEFAULT_GENERATE_ABI_VERSION: usize = 13;

/// Build the grammar at SRC_PATH and place into DST_PATH.
///
/// Not intended to be used directly, see `tsc-build-parser-from-source'.
#[defun]
fn _build_parser_from_source(src_path: String, dst_path: String, generate: Value) -> Result<()> {
    let abi_version = DEFAULT_GENERATE_ABI_VERSION;
    let parsed_repo_path = PathBuf::from(&src_path);
    if generate.is_not_nil() {
        generate::generate_parser_in_directory(
            &parsed_repo_path,
            None,
            abi_version,
            false,
            None,
        )?;
    }
    let loader = tree_sitter_loader::Loader::with_parser_lib_path(Path::new(&dst_path).to_path_buf());
    let source_path = parsed_repo_path.join("src");
    loader.load_language_at_path(source_path.as_path(), source_path.as_path())?;
    Ok(())
}
