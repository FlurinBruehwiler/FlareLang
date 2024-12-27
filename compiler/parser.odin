package compiler

import "core:fmt"

/*

	Node
		Ast_Statement
			Ast_If_Statement
			Ast_Block_Statement
			Ast_Assignement_Statement
		Ast_Expression
			Ast_Number_Expression
			Ast_Symbol_Expression
			Ast_Binary_Expression
*/

Ast :: struct {
}

Ast_Procedure :: struct {
	type_identifier: Token,
	name: Token,
	parameters: []Ast_Parameter,
	body: ^Ast_Statement
}

Ast_Parameter :: struct {
	type_identifier: Token,
	name: Token
}

Ast_Node :: struct {
	pos_start: Pos,
	pos_end: Pos
}

Ast_Statement :: struct {
	statement_base: Ast_Node
}

Ast_If_Statement :: struct {
	using if_statement_base: Ast_Statement,
	condition: ^Ast_Expression,
	body: ^Ast_Statement
}

Ast_Assignement_Statement :: struct {
	using assignement_statement_base: Ast_Statement,
	left: ^Ast_Expression,
	right: ^Ast_Expression
}

Ast_Block_Statement :: struct {
	using block_statement_base: Ast_Statement,
	statements: []Ast_Statement
}

Ast_Expression :: struct {
	using expression_base: Ast_Node
}

Ast_Number_Expression :: struct {
	using number_expression_base : Ast_Expression,
	value: int
}

Ast_Identifier_Expression :: struct {
	using number_expression_base : Ast_Expression,
	identifier: string
}

Ast_Binary_Expression :: struct {
	using number_expression_base: Ast_Expression,
	left: ^Ast_Expression,
	operator: Token,
	right: ^Ast_Expression
}

Ast_Literal_Expression :: struct {
	using literal_expression_base: Ast_Expression,
	literal: Token
}

Parser :: struct {
	tokenizer: Tokenizer,
	lookahead: Token
}

parse :: proc(content: string, file_path: string) -> ^Ast {
	fmt.println("Start Parsing")

	tokenizer := create_tokenizer(content, file_path)

/*
	for {
		t := scan(&tokenizer)
		
		print_token(t)
		if t.kind == .EOF {
			break
		}
	}
*/
	
	parser: Parser
	parser.tokenizer = tokenizer
	advance_token(&parser)

	parse_proc(&parser)

	fmt.println("End parsing")

	return nil
}

parse_proc :: proc(p: ^Parser) -> Ast_Procedure{
	ast_procedure: Ast_Procedure

	ast_procedure.type_identifier = parser_eat(p, .Identifier)
	ast_procedure.name = parser_eat(p, .Identifier)

	parser_eat(p, .Open_Parenthesis)

	parameters : [dynamic]Ast_Parameter

	//parameters
	for {
		if p.lookahead.kind == .Close_Parenthesis {
			break
		}

		parameter : Ast_Parameter

		parameter.type_identifier = parser_eat(p, .Identifier)
		parameter.name = parser_eat(p, .Identifier)

		append(&parameters, parameter)
	}

	ast_procedure.parameters = parameters[:]

	parser_eat(p, .Close_Parenthesis)

	ast_procedure.body = parse_block_statement(p)

	return ast_procedure
}

parse_statement :: proc(p: ^Parser) -> Ast_Statement {

	fmt.printfln("%v", p.lookahead.kind)
	#partial switch p.lookahead.kind {
		case .If:
			return parse_if_statement(p)
	}

	expr := parse_expression(p)
	if p.lookahead.kind == .Equal {
		fmt.println("Detected assignement")

		parser_eat(p, .Equal)
		right := parse_expression(p)
		n, _ := new(Ast_Assignement_Statement)
		n.left = expr
		n.right = right
		return n
	}

	return Ast_Statement {

	}
}

parse_if_statement :: proc(p: ^Parser) -> Ast_If_Statement {
	fmt.println("if start")

	parser_eat(p, .If)
	parser_eat(p, .Open_Parenthesis)
	condition := parse_expression(p)
	parser_eat(p, .Close_Parenthesis)
	body := parse_block_statement(p)

	fmt.println("if end")

	return Ast_If_Statement {
		condition = condition,
		body = body
	}
}

parse_block_statement :: proc(p: ^Parser) -> ^Ast_Block_Statement {
	fmt.println("block start")
	parser_eat(p, .Open_Brace)

	statements : [dynamic]Ast_Statement

	for {
		if p.lookahead.kind == .Close_Brace {
			break
		}

		append(&statements, parse_statement(p))
	}

	parser_eat(p, .Close_Brace)
	fmt.println("block end")

	statement := new(Ast_Block_Statement)
	statement.statements = statements[:]

	return statement
}

parse_expression :: proc(p: ^Parser) -> ^Ast_Expression {
	return parse_binary_expression(p, 1)
}

parse_binary_expression :: proc(p: ^Parser, prec: int) -> ^Ast_Expression {
	expression := parse_unary_expression(p)
	op := p.lookahead
	parser_eat(p, op.kind)
	right := parse_binary_expression(p, prec + 1)

	n, _ := new(Ast_Binary_Expression)
	n.left = expression
	n.operator = op
	n.right = right
	return n
}

parse_unary_expression :: proc(p: ^Parser) -> ^Ast_Expression {
	#partial switch p.lookahead.kind {
		case .Number:
			n, _ := new(Ast_Literal_Expression)
			n.literal = parser_eat(p, .Number)
			return n
		case .Identifier:
			n, _ := new(Ast_Identifier_Expression)
			n.identifier = parser_eat(p, .Identifier).text
			return n
	}
	assert(false)
	return nil
}

token_precedence :: proc(p: ^Parser, kind: Token_Kind) -> int {
	#partial switch kind {
		case .Equal, .Not_Equal, .Greater, .Greater_Equal, .Lesser, .Lesser_Equal:
			return 1
		case .Add, .Subtract:
			return 2
		case .Multiply, .Divide:
			return 3
	}
	return 0
}

parser_eat :: proc(p: ^Parser, kind: Token_Kind) -> Token{
	if p.lookahead.kind != kind {
		fmt.printfln("Unexpected token %v, expected %v", p.lookahead.kind, kind)
		assert(false)
	}else{
		fmt.printfln("Eating token %v", kind)
		assert(kind != .EOF)
	}
	prev := p.lookahead
	advance_token(p)
	return prev
}

advance_token :: proc(p: ^Parser) -> bool{
	p.lookahead = scan(&p.tokenizer)
	if p.lookahead.kind == .EOF {
		return false
	}
	return true
}