package compiler

import "core:fmt"
import "core:strconv"

parse :: proc(content: string, file_path: string) -> Ast_Node {
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

	return Ast_Statement(parse_block_statement(&parser))
}

parse_proc :: proc(p: ^Parser) -> ^Ast_Procedure{
	ast_procedure, n := new(Ast_Procedure)

	ast_procedure.type_identifier = parser_eat(p, .Identifier)
	ast_procedure.name = parser_eat(p, .Identifier)

	parser_eat(p, .Open_Parenthesis)

	parameters : [dynamic]^Ast_Parameter

	//parameters
	for {
		if p.lookahead.kind == .Close_Parenthesis {
			break
		}

		parameter, _ := new(Ast_Parameter) 

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

	#partial switch p.lookahead.kind {
		case .If:
			return parse_if_statement(p)
		case .Var:
			return parse_declaration_statement(p)
		case .Print:
			return parse_print_statement(p)
		case .For:
			return parse_for_statement(p)
		case .Open_Brace:
			return parse_block_statement(p)
	}

	expr := parse_expression(p)
	if p.lookahead.kind == .Equal {

		parser_eat(p, .Equal)
		right := parse_expression(p)
		parser_eat(p, .Semicolon)

		n, _ := new(Ast_Assignement_Statement)
		n.left = expr
		n.right = right
		return n
	}

	parser_eat(p, .Semicolon)

	n, _ := new(Ast_Expression_Statement)
	n.expression = expr

	return n
}

parse_for_statement :: proc(p: ^Parser) -> ^Ast_For_Statement {
	parser_eat(p, .For)
	parser_eat(p, .Open_Parenthesis)
	condition := parse_expression(p)
	parser_eat(p, .Close_Parenthesis)

	body := parse_statement(p)

	statement := new(Ast_For_Statement)
	statement.condition = condition
	statement.body = body

	return statement
}

parse_print_statement :: proc(p: ^Parser) -> ^Ast_Procedure_Invocation {
	parser_eat(p, .Print)
	parser_eat(p, .Open_Parenthesis)
	expression := parse_expression(p)
	parser_eat(p, .Close_Parenthesis)
	parser_eat(p, .Semicolon)

	statement := new(Ast_Procedure_Invocation)
	statement.parameter = expression

	return statement
}

parse_declaration_statement :: proc(p: ^Parser) -> ^Ast_Declaration_Statement {
	parser_eat(p, .Var)

	identifier := parse_identifier(p)

	parser_eat(p, .Equal)

	expression := parse_expression(p)

	parser_eat(p, .Semicolon)

	statement := new(Ast_Declaration_Statement)
	statement.identifier = identifier
	statement.expression = expression

	return statement
}

parse_if_statement :: proc(p: ^Parser) -> ^Ast_If_Statement {
	parser_eat(p, .If)
	parser_eat(p, .Open_Parenthesis)
	condition := parse_expression(p)
	parser_eat(p, .Close_Parenthesis)

	body := parse_statement(p)

	statement := new(Ast_If_Statement)
	statement.condition = condition
	statement.body = body

	if p.lookahead.kind == .Else {
		parser_eat(p, .Else)
		if p.lookahead.kind == .If {
			statement.else_statement = parse_if_statement(p)
		}else{
			statement.else_statement = parse_block_statement(p)
		}
	}

	return statement
}

parse_block_statement :: proc(p: ^Parser) -> ^Ast_Block_Statement {
	parser_eat(p, .Open_Brace)

	statements: [dynamic]Ast_Statement

	for {
		if p.lookahead.kind == .Close_Brace {
			break
		}

		append(&statements, parse_statement(p))
	}

	parser_eat(p, .Close_Brace)

	statement := new(Ast_Block_Statement)
	statement.statements = statements[:]

	return statement
}

parse_expression :: proc(p: ^Parser) -> Ast_Expression {
	return parse_binary_expression(p, -999)
}

parse_binary_expression :: proc(p: ^Parser, prev_prec: int) -> Ast_Expression {
	expression := parse_unary_expression(p)

	for {
		if p.lookahead.kind == .EOF || p.lookahead.kind == .Close_Parenthesis || p.lookahead.kind == .Equal || p.lookahead.kind == .Semicolon {
			return expression
		}

		prec := token_precedence(p, p.lookahead.kind)

		if prec <= prev_prec {
			return expression
		}

		op := p.lookahead
		parser_eat(p, op.kind)

		right := parse_binary_expression(p, prec)

		n, _ := new(Ast_Binary_Expression)
		n.left = expression
		n.operator = op
		n.right = right

		expression = n
	}

	
	return expression
}

parse_identifier :: proc(p: ^Parser) -> ^Ast_Identifier_Expression {
	n, _ := new(Ast_Identifier_Expression)
	n.identifier = parser_eat(p, .Identifier).text
	return n
}

parse_unary_expression :: proc(p: ^Parser) -> Ast_Expression {
	#partial switch p.lookahead.kind {
		case .Number:
			n, _ := new(Ast_Number_Expression)
			n.value = i32(strconv.atoi(parser_eat(p, .Number).text))
			return n
		case .Identifier:
			return parse_identifier(p)
		case .Open_Parenthesis:

			parser_eat(p, .Open_Parenthesis)

			n, _ := new(Ast_Parenthesis_Expression)
			n.expression = parse_expression(p) 

			parser_eat(p, .Close_Parenthesis)

			return n
	}
	fmt.printfln("Unexpected token %v, is not a valid unary expression", p.lookahead.kind)
	assert(false)
	return nil
}

token_precedence :: proc(p: ^Parser, kind: Token_Kind) -> int {
	#partial switch kind {
		case .Double_Equal, .Not_Equal, .Greater, .Greater_Equal, .Lesser, .Lesser_Equal:
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
		//fmt.printfln("Eating token %v", kind)
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