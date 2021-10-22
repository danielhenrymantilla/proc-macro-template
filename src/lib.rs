#![cfg_attr(feature = "better-docs",
    cfg_attr(all(), doc = include_str!("../README.md")),
)]
#![no_std]
#![forbid(unsafe_code)]

#[cfg(any())]
pub
mod prelude {
    // …
}
{% if proc_macros %}
/*
/// DOCS FOR IMPORTED THINGS
*/
#[doc(inline)]
pub use ::{{crate_name}}_proc_macros::{
    /* some_macro_name, */
};
{% endif %}
// macro internals
#[doc(hidden)] /** Not part of the public API */ pub
mod __ {
}

#[cfg_attr(feature = "ui-tests",
    cfg_attr(all(), doc = include_str!("compile_fail_tests.md")),
)]
mod _compile_fail_tests {}
