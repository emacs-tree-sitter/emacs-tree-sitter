use std::{cell::RefCell, rc::Rc};

use emacs::{defun, Result, Value, Vector, Env, ResultExt};
use tree_sitter::{Parser, Tree};

use crate::{
    types::{BytePos, Point, Range, Shared},
    lang::Language,
    error,
};

fn shared<T>(t: T) -> Shared<T> {
    Rc::new(RefCell::new(t))
}

impl_pred!(parser_p, &RefCell<Parser>);

/// Create a new parser.
#[defun(user_ptr)]
fn make_parser() -> Result<Parser> {
    Ok(Parser::new())
}

/// Set the LANGUAGE that PARSER should use for parsing.
///
/// This may fail if there was a version mismatch: the loaded LANGUAGE was generated
/// with an incompatible version of tree-sitter-cli.
#[defun]
fn set_language(parser: &mut Parser, language: Language, env: &Env) -> Result<()> {
    parser.set_language(&language.0).or_signal(env, error::tsc_lang_abi_error)
}

/// Return PARSER's current language.
#[defun(mod_in_name = true)]
fn language(parser: &Parser) -> Result<Option<Language>> {
    Ok(parser.language().map(|l| l.into()))
}

// TODO: Add a version that reuses a single byte buffer to avoid multiple allocations. Also allow
// `parse` to pass a soft size limit to the input function.

// TODO: Add parse_buffer.

/// Parse source code chunks generated by INPUT-FUNCTION with PARSER; return a tree.
///
/// INPUT-FUNCTION should take 3 parameters: (BYTEPOS LINE-NUMBER BYTE-COLUMN), and
/// return a fragment of the source code, starting from the position identified by
/// either BYTEPOS or (LINE-NUMBER . BYTE-COLUMN). It should return an empty string
/// to signal the end of the source code.
///
/// BYTEPOS is Emacs's 1-based byte position.
///
/// LINE-NUMBER is the number returned by `line-number-at-pos', which counts from 1.
///
/// BYTE-COLUMN counts from 0, likes Emacs's `current-column'. However, unlike that
/// function, it counts bytes, instead of displayed glyphs.
///
/// If you have already parsed an earlier version of this document, and it has since
/// been edited, pass the previously parsed OLD-TREE so that its unchanged parts can
/// be reused. This will save time and memory. For this to work correctly, you must
/// have already edited it using `tsc-edit-tree' function in a way that exactly
/// matches the source code changes.
#[defun]
fn parse_chunks(parser: &mut Parser, input_function: Value, old_tree: Option<&Shared<Tree>>) -> Result<Shared<Tree>> {
    let old_tree = match old_tree {
        Some(v) => Some(v.try_borrow()?),
        _ => None,
    };
    let old_tree = match &old_tree {
        Some(r) => Some(&**r),
        _ => None,
    };
    // This is used to hold potential error, because the callback cannot return a Result, and
    // unwinding across FFI boundary during a panic is UB (future Rust versions will abort).
    // See https://github.com/rust-lang/rust/issues/52652.
    let mut input_error = None;
    let input = &mut |byte: usize, point: tree_sitter::Point| -> String {
        let bytepos: BytePos = byte.into();
        let point: Point = point.into();
        input_function.call((bytepos, point.line_number(), point.byte_column()))
            .and_then(|v| v.into_rust())
            .unwrap_or_else(|e| {
                input_error = Some(e);
                "".to_owned()
            })
    };
    // TODO: Support error cases (None).
    let tree = parser.parse_with(input, old_tree).unwrap();
    match input_error {
        None => Ok(shared(tree)),
        Some(e) => Err(e),
    }
}

/// Use PARSER to parse the INPUT string, returning a tree.
#[defun]
fn parse_string(parser: &mut Parser, input: String) -> Result<Shared<Tree>> {
    let tree = parser.parse(input, None).unwrap();
    Ok(shared(tree))
}

/// Instruct PARSER to start the next parse from the beginning.
///
/// If PARSER previously failed because of a timeout or a cancellation, then by
/// default, it will resume where it left off on the next parse. If you don't want
/// to resume, and instead intend to use PARSER to parse some other code, you must
/// call this function first.
///
/// Note: timeout and cancellation are not yet properly supported.
#[defun]
fn _reset_parser(parser: &mut Parser) -> Result<()> {
    Ok(parser.reset())
}

/// Return the duration in microseconds that PARSER is allowed to take each parse.
/// Note: timeout and cancellation are not yet properly supported.
#[defun]
fn _timeout_micros(parser: &Parser) -> Result<u64> {
    Ok(parser.timeout_micros())
}

/// Set MAX-DURATION in microseconds that PARSER is allowed to take each parse.
/// Note: timeout and cancellation are not yet properly supported.
#[defun]
fn _set_timeout_micros(parser: &mut Parser, max_duration: u64) -> Result<()> {
    Ok(parser.set_timeout_micros(max_duration))
}

/// Set the RANGES of text that PARSER should include when parsing.
///
/// By default, PARSER will always include entire documents. This function allows
/// you to parse only a portion of a document but still return a syntax tree whose
/// ranges match up with the document as a whole. RANGES should be a vector, and can
/// be disjointed.
///
/// This is useful for parsing multi-language documents.
#[defun]
fn set_included_ranges(parser: &mut Parser, ranges: Vector) -> Result<()> {
    let len = ranges.len();
    let included = &mut Vec::with_capacity(len);
    for i in 0..len {
        let range: Range = ranges.get(i)?;
        included.push(range.into());
    }
    parser.set_included_ranges(included).or_else(|error| {
        ranges.value().env.signal(error::tsc_invalid_ranges, (error.0, ))
    })
}
