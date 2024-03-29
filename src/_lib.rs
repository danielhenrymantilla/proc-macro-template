#![doc = include_str!("../README.md")]
#![no_std]
#![forbid(unsafe_code)]

use {
    ::core::{
        ops::Not as _,
    },
};

#[cfg(COMMENTED_OUT)] // <- Remove this when used!
/// The crate's prelude.
pub
mod prelude {
    // …
}
{% if proc_macros %}
#[doc(inline)]
pub use ::{{crate_name}}_proc_macros::*;

// To get fancier docs, for each exported procedural macro, put the docstring
// here, on the re-export, rather than on the proc-macro function definition.
// Indeed, this way, the internal doc links will Just Work™.
#[cfg(COMMENTED_OUT)] // <- Remove this when used!
/// Docstring for the proc-macro.
pub use ::{{crate_name}}_proc_macros::some_macro_name;
{% endif %}
// macro internals
#[doc(hidden)] /** Not part of the public API */ pub
mod ඞ {
    pub use ::core; // or `std`
}

#[doc = include_str!("compile_fail_tests.md")]
mod _compile_fail_tests {}
