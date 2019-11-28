#[macro_use]
extern crate {{crate_name}};

/// mul documentation
#[my_attribute_macro(/* attrs */)]
fn mul (x: i32, y: i32) -> i32
{
    x * y
}

/// Foo documentation
#[derive(MyMacroDerive)]
union DaedC0de {
    field: (),
}

fn main ()
{
    // A procedural macro in expression position, thanks to `proc_macro_hack`
    let foo = my_function_like_macro!("Hello", "World!");
    foo();
    bar();
    baz();
}
