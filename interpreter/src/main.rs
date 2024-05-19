use std::fs;

mod lexer;
mod ast;
mod pratt;
mod evaluating;

fn main() {
    let file_path = "./programs/program.lox";

    let contents = fs::read_to_string(file_path).unwrap_or_else(|error| {
        eprintln!("Error reading file: {}", error);
        std::process::exit(1);
    });

    println!("{}", contents);
}
