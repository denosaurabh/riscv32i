use std::fmt;

#[derive(Debug, Clone)]
enum S {
    Atom(char),
    Cons(char, Vec<S>),
}
impl fmt::Display for S {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            S::Atom(i) => write!(f, "{}", i),
            S::Cons(head, rest) => {
                write!(f, "({}", head)?;
                for s in rest {
                    write!(f, " {}", s)?
                }
                write!(f, ")")
            }
        }
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Token {
    Atom(char),
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
                '0'..='9'
                | 'a'..='z' | 'A'..='Z' => Token::Atom(c),
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

fn expr(input: &str) -> S {
    let mut lexer = Lexer::new(input);
    expr_bp(&mut lexer, 0)
}

fn expr_bp(lexer: &mut Lexer, min_bp: u8) -> S {
    println!(" ");
    println!("peek: {:?} min_bp {:?}", lexer.peek(), min_bp);

    let mut lhs = match lexer.next() {
        Token::Atom(it) => {
            println!("atom: {:?}", it);

            S::Atom(it)
        },
        Token::Op('(') => {
            println!("(");

            let lhs = expr_bp(lexer, 0);
            assert_eq!(lexer.next(), Token::Op(')'));
            lhs
        }
        Token::Op(op) => {
            println!("op: {:?}", op);

            let ((), r_bp) = prefix_binding_power(op);
            let rhs = expr_bp(lexer, r_bp);
            S::Cons(op, vec![rhs])
        }
        t => panic!("bad token: {:?}", t),
    };
    loop {
        let op = match lexer.peek() {
            Token::Eof => {
                println!("EOF");
                break
            },
            Token::Op(op) => op,
            t => panic!("bad token: {:?}", t),
        };
        // println!("LOOOP");
        println!("loop op: {:?}", op);

        if let Some((l_bp, ())) = postfix_binding_power(op) {
            println!("postfix: {:?}", op);
            println!("min_bp: {:?}, l_bp {:?}", min_bp, l_bp);

            if l_bp < min_bp {
                println!("l_bp < min_bp");
                break;
            }
            lexer.next();
            lhs = if op == '[' {
                let rhs = expr_bp(lexer, 0);
                assert_eq!(lexer.next(), Token::Op(']'));
                S::Cons(op, vec![lhs, rhs])
            } else {
                S::Cons(op, vec![lhs])
            };

            println!("postfix_binding_power: lhs: {:?}", lhs);

            continue;
        }
        if let Some((l_bp, r_bp)) = infix_binding_power(op) {
            println!("infix_binding_power: {:?}", op);
            println!("min_bp: {:?}, l_bp {:?}, r_bp {:?}", min_bp, l_bp, r_bp);

            if l_bp < min_bp {
                println!("l_bp < min_bp");
                break;
            }
            lexer.next();
            lhs = if op == '?' {
                let mhs = expr_bp(lexer, 0);
                assert_eq!(lexer.next(), Token::Op(':'));
                let rhs = expr_bp(lexer, r_bp);
                S::Cons(op, vec![lhs, mhs, rhs])
            } else {
                let rhs = expr_bp(lexer, r_bp);
                S::Cons(op, vec![lhs, rhs])
            };

            println!("infix_binding_power: lhs: {:?}", lhs);

            continue;
        }

        // println!("LOOOP BREAK");

        break;
    }

    println!("LHS: {:?}", lhs);
    println!(" ");

    lhs
}
fn prefix_binding_power(op: char) -> ((), u8) {
    match op {
        '+' | '-' => ((), 9),
        _ => panic!("bad op: {:?}", op),
    }
}
fn postfix_binding_power(op: char) -> Option<(u8, ())> {
    let res = match op {
        '!' => (11, ()),
        '[' => (11, ()),
        _ => return None,
    };
    Some(res)
}
fn infix_binding_power(op: char) -> Option<(u8, u8)> {
    let res = match op {
        '=' => (2, 1),
        '?' => (4, 3),
        '+' | '-' => (5, 6),
        '*' | '/' => (7, 8),
        '.' => (14, 13),
        _ => return None,
    };
    Some(res)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn text_my() {
        let s = expr("1 * 2 + 3");
        assert_eq!(s.to_string(), "(+ (* 1 2) 3)");
    }

    #[test]
    fn text_all() {
        let s = expr("1");
        assert_eq!(s.to_string(), "1");
        let s = expr("1 + 2 * 3");
        assert_eq!(s.to_string(), "(+ 1 (* 2 3))");
        let s = expr("1 * 2 + 3");
        assert_eq!(s.to_string(), "(+ (* 1 2) 3)");
        let s = expr("a + b * c * d + e");
        assert_eq!(s.to_string(), "(+ (+ a (* (* b c) d)) e)");
        let s = expr("f . g . h");
        assert_eq!(s.to_string(), "(. f (. g h))");
        let s = expr(" 1 + 2 + f . g . h * 3 * 4");
        assert_eq!(
            s.to_string(),
            "(+ (+ 1 2) (* (* (. f (. g h)) 3) 4))",
        );
        let s = expr("--1 * 2");
        assert_eq!(s.to_string(), "(* (- (- 1)) 2)");
        let s = expr("--f . g");
        assert_eq!(s.to_string(), "(- (- (. f g)))");
        let s = expr("-9!");
        assert_eq!(s.to_string(), "(- (! 9))");
        let s = expr("f . g !");
        assert_eq!(s.to_string(), "(! (. f g))");
        let s = expr("(((0)))");
        assert_eq!(s.to_string(), "0");
        let s = expr("x[0][1]");
        assert_eq!(s.to_string(), "([ ([ x 0) 1)");
        let s = expr(
            "a ? b :
            c ? d
            : e",
        );
        assert_eq!(s.to_string(), "(? a b (? c d e))");
        let s = expr("a = 0 ? b : c = d");
        assert_eq!(s.to_string(), "(= a (= (? 0 b c) d))")
    }
}

