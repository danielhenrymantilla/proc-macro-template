//! Crate not intended for direct use.
//! Use https:://docs.rs/{{project-name}} instead.
// Templated by `cargo-generate` using https://github.com/danielhenrymantilla/proc-macro-template
#![allow(nonstandard_style, unused_imports)]

use ::core::{
    mem,
    ops::Not as _,
};
use ::proc_macro::{
    TokenStream,
};
use ::proc_macro2::{
    Span,
    TokenStream as TokenStream2,
    TokenTree as TT,
};
use ::quote::{
    format_ident,
    quote,
    quote_spanned,
    ToTokens,
};
use ::syn::{*,
    parse::{Parse, Parser, ParseStream},
    punctuated::Punctuated,
    Result, // Explicitly shadow it
    spanned::Spanned,
};

///
#[proc_macro_attribute] pub
fn an_attr (
    attrs: TokenStream,
    input: TokenStream,
) -> TokenStream
{
    an_attr_impl(attrs.into(), input.into())
    //  .map(|ret| { println!("{}", ret); ret })
        .unwrap_or_else(|err| {
            let mut errors =
                err .into_iter()
                    .map(|err| Error::new(
                        err.span(),
                        format_args!("`#[{{crate_name}}::an_attr]`: {}", err),
                    ))
            ;
            let mut err = errors.next().unwrap();
            errors.for_each(|cur| err.combine(cur));
            err.to_compile_error()
        })
        .into()
}

fn an_attr_impl (
    attrs: TokenStream2,
    input: TokenStream2,
) -> Result<TokenStream2>
{
    // By default deny any attribute present.
    let _: parse::Nothing = parse2(attrs)?;
    todo!()
}
