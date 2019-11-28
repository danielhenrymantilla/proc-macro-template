#![allow(unused_imports)]

extern crate proc_macro;

use ::proc_macro::TokenStream;
use ::proc_macro2::{
    Span,
    TokenStream as TokenStream2,
};
use ::proc_macro_hack::proc_macro_hack;
use ::quote::{
    quote,
    quote_spanned,
    ToTokens,
};
use ::syn::{*,
    parse::{
        Parse,
        Parser,
        ParseStream,
    },
    punctuated::Punctuated,
    spanned::Spanned,
    Result,
};

#[proc_macro_hack] pub
fn my_function_like_macro (input: TokenStream)
  -> TokenStream
{
    let args: Vec<Expr> = {
        let parser = Punctuated::<Expr, Token![,]>::parse_terminated;
        match parser.parse(input) {
            | Ok(exprs) => exprs.into_iter().collect(),
            | Err(err) => return err.to_compile_error().into(),
        }
    };
    let args_as_string: String =
        args
            .into_iter()
            .map(|arg| format!("  - `{}`\n", arg.into_token_stream()))
            .collect()
    ;
    let args_as_string_literal = LitStr::new(
        &args_as_string,
        Span::call_site(),
    );
    let my_fancy_expr: Expr = parse_quote! {
        // parse_quote! is very useful to generate new syn elements.
        // Here it infers that the tokens need to be interpolated as
        // an `Expr`
        ::{{crate_name}}::MyStruct // we can mention non proc-macro stuff
    };
    TokenStream::from(quote! {
        || {
            let _ = #my_fancy_expr;
            println!(
                concat!(
                    "`#[my_attribute_macro]` ",
                    "was called with the following args:\n{}\n\n",
                ),
                #args_as_string_literal,
            )
        }
    })
}

#[proc_macro_derive(MyMacroDerive)] pub
fn this_name_plays_no_role_whatsoever (input: TokenStream)
  -> TokenStream
{
    let input: DeriveInput = parse_macro_input!(input);
    TokenStream::from(quote! {
        fn bar ()
        {
            println!(
                "`#[derive(MyMacroDerive)]` was called on:\n{}\n\n",
                stringify!(#input),
            );
        }
    })
}

#[proc_macro_attribute] pub
fn my_attribute_macro (
    attrs: TokenStream,
    input: TokenStream,
) -> TokenStream
{
    let input: ItemFn = parse_macro_input!(input);
    if let Some(token_tree) = TokenStream2::from(attrs).into_iter().next() {
        return Error::new(
            token_tree.span(), // Error will highlight this.
            "`#[my_attribute_macro]` takes no parameters"
        ).to_compile_error().into();
    }
    let input_span = input.span();
    let input_as_string_literal = LitStr::new(
        &input.into_token_stream().to_string(),
        input_span,
    );
    TokenStream::from(quote_spanned! { input_span =>
        fn baz ()
        {
            println!(
                "`#[my_attribute_macro]` was called on:\n{}\n\n",
                #input_as_string_literal,
            );
        }
    })
}
