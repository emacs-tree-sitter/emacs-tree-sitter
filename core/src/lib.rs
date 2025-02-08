
use emacs::{Env, Result};

#[macro_use]
mod types;
mod error;
mod lang;
mod parser;
mod tree;
mod node;
mod cursor;
mod query;
mod build;

emacs::plugin_is_GPL_compatible! {}

#[emacs::module(name = "tsc-dyn", defun_prefix = "tsc", mod_in_name = false)]
fn init(env: &Env) -> Result<()> {
    env.call("set", (env.intern("tsc-dyn--version")?, option_env!("CARGO_PKG_VERSION")))?;
    Ok(())
}

