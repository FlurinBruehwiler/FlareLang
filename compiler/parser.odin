package compiler

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

Ast_Statement :: struct {

}

Ast_If_Statement :: struct {
	using node: Ast_Statement,
	condition: ^Ast_Expression,
	body: ^Ast_Statement
}

Ast_Block_Statement :: struct {
	using node: Ast_Statement,
	statements: []Ast_Statement
}

Ast_Expression :: struct {

}

Parser :: struct {
	tokenizer: Tokenizer,
	lookahead: Token
}

parse :: proc(content: string, file_path: string) -> Ast {
	tokenizer := create_tokenizer(content, file_path)

	for {
		token := scan(&tokenizer)
		print_token(token)
		if token.kind == .EOF {
			break
		}
	}

	return Ast {

	}
}

parse_proc :: proc(p: ^Parser) -> Ast_Procedure{

	ast_procedure : Ast_Procedure

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

parser_statement :: proc(p: ^Parser) -> Ast_Statement {
	#partial switch p.lookahead.kind {
		case .If:
			return parse_if_statement(p)
	}

	return Ast_Statement {

	}
}

parse_if_statement :: proc(p: ^Parser) -> Ast_If_Statement {
	parser_eat(p, .If)
	parser_eat(p, .Open_Parenthesis)
	condition := parse_expression(p)
	parser_eat(p, .Close_Parenthesis)
	body := parse_block_statement(p)

	return Ast_If_Statement {
		condition = condition,
		body = body
	}
}

parse_block_statement :: proc(p: ^Parser) -> ^Ast_Block_Statement {
	parser_eat(p, .Open_Brace)

	statements : [dynamic]Ast_Statement

	for {
		if p.lookahead.kind == .Close_Brace {
			break
		}

		append(&statements, parser_statement(p))
	}

	parser_eat(p, .Close_Brace)

	statement := new(Ast_Block_Statement)
	statement.statements = statements[:]

	return statement
}

parse_expression :: proc(p: ^Parser) -> ^Ast_Expression {
	return parse_binary_expression(p, 1)
}

parse_binary_expression :: proc(p: ^Parser, prec: int) -> ^Ast_Expression {

}

parser_eat :: proc(p: ^Parser, kind: Token_Kind) -> Token{
	if p.lookahead.kind != kind {

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