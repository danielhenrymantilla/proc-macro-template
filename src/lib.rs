#[::proc_macro_hack::proc_macro_hack] // <-- usable in expression position ---+
pub use ::proc_macro::{                                                    // |
    my_function_like_macro, // function-like proc-macro ----------------------+
};

pub use ::proc_macro::{
    my_attribute_macro, // attribute proc-macro
    MyMacroDerive, // Derive proc-macro
};

/// Non proc-macro items can be exported here
pub
struct MyStruct;
