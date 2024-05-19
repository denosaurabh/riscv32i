// use crate::lexer::{Lexer, TokenType};

// #[derive(Debug, Clone)]
// pub enum ASTNode {
//     Number(f64),
//     Boolean(bool),
//     String(String),

//     Operator(Box<ASTNode>, Operator, Box<ASTNode>),
//     UnaryOp(UnaryOp, Box<ASTNode>),
//     Grouping(Box<ASTNode>),
// }

// #[derive(Debug, Clone, Copy, PartialEq)]
// pub enum UnaryOp {
//     Negate,
//     Not,
// }

// #[derive(Debug, Clone, Copy, PartialEq)]
// pub enum Operator {
//     Add,
//     Sub,
//     Mul,
//     Div,

//     Equal, 
//     NotEqual,
//     LessThan, 
//     LessThanOrEqual, 
//     GreaterThan, 
//     GreaterThanOrEqual,
// }

// //////////////////////////////
// /// Parser
// //////////////////////////////

// pub struct Parser<'a> {
//     lexer: &'a mut Lexer,
// }

// impl Parser {
//     pub fn new(lexer: &mut Lexer) -> Parser {
//         Parser { lexer }
//     }

//     pub fn parse(&mut self) -> Vec<ASTNode> {
//         let mut statements = vec![];

//         while self.lexer.peek().token_type != TokenType::EOF {
//             let statements = match self.lexer.peek().token_type {
//                 TokenType::Number(_) |
//                 TokenType::String |
//                 TokenType::Boolean(_) => {
                    
//                 },
//                 TokenType::LeftParen => {

//                 },
//                 TokenType::BANG | TokenType::MINUS => self.parse_unary(),
//                 TokenType::PLUS | TokenType::MINUS | TokenType::STAR | TokenType::SLASH | TokenType::BangEqual  => {
//                     self.parse_binary()
//                 },
//                 _ => self.parse_expression()
//             };

//             statements.push(statements);
//         }

//         statements
//     }

//     pub fn parse_expression(&mut self) -> ASTNode {

//     }

//     pub fn parse_unary(&mut self) -> ASTNode {

//     }

//     pub fn parse_grouping(&mut self) -> ASTNode {

//     }

//     pub fn parse_binary(&mut self) -> ASTNode {

//     }

//     pub fn parse_literal(&mut self) -> ASTNode {

//     }

// }