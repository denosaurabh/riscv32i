

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Token {
    Atom(char),
    LeftParen,
    RightParen,
    Op(char),
    Eof,
}

struct Lexer {
    tokens: Vec<Token>,
}
impl Lexer {
    fn new(input: &str) -> Lexer {

        let mut tokens = input
            .chars()
            .filter(|it| !it.is_ascii_whitespace())
            .map(|c| match c {
                '0'..='9' => Token::Atom(c),
                '(' => Token::LeftParen,
                ')' => Token::RightParen,
                _ => Token::Op(c),
            })
            .collect::<Vec<_>>();
        tokens.reverse();

        println!("{:?}", tokens);

        Lexer { tokens }
    }
    fn next(&mut self) -> Token {
        self.tokens.pop().unwrap_or(Token::Eof)
    }
    fn peek(&mut self) -> Token {
        self.tokens.last().copied().unwrap_or(Token::Eof)
    }
}


fn expr(input: &str) -> String {
    let mut lexer = Lexer::new(input);
    evalulate(&mut lexer)
}

fn evalulate(lex: &mut Lexer) -> Number {
    let res = match lex.peek() {
        Token::LeftParen => {
            let op = lex.next();

            // can be any operation
            assert_eq!(op, Token::Op);


            let l = evalulate(lex.next());
            let r = evalulate(lex.next());

            
            

        },
        Token::Atom(it) => {
            // convert char to number
            let num = it.to_digit(10).unwrap() as f64;
            num
        },
        Token::Op(op) => {

            let l = evalulate(lex.next());
            let r = evalulate(lex.next());

            let lhs = expr(lex.next());
            assert_eq!(lex.next(), Token::Op(')'));
            lhs
        }
        _ => "".to_string()
    };


    res
}



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn text_my() {
        let s = expr("(+ 1 (* 2 3))");
        println!("{:?}", s);

        // assert_eq!(s.to_string(), "(+ (* 1 2) 3)");
    }


}