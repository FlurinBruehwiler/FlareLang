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

Ast_Procedure :: struct {
	type_identifier: Token,
	name: Token,
	parameters: []^Ast_Parameter,
	body: Ast_Statement
}

Ast_Parameter :: struct {
	type_identifier: Token,
	name: Token
}

Ast_Node :: union {
	//other unions
	Ast_Statement,
	Ast_Expression,
	
	^Ast_Procedure,
	^Ast_Parameter,

/*
	//Statements
	^Ast_If_Statement,
	^Ast_Assignement_Statement,
	^Ast_Block_Statement,
	^Ast_Expression_Statement,

	//Expressions
	^Ast_Number_Expression,
	^Ast_Identifier_Expression,
	^Ast_Binary_Expression,
	^Ast_Literal_Expression,
	^Ast_Negate_Expression,
	^Ast_Parenthesis_Expression
	*/
}

Ast_Statement :: union {
	^Ast_If_Statement,
	^Ast_Assignement_Statement,
	^Ast_Block_Statement,
	^Ast_Expression_Statement,
	^Ast_Declaration_Statement,
	^Ast_Procedure_Invocation
}

Ast_If_Statement :: struct {
	condition: Ast_Expression,
	body: Ast_Statement,
	else_statement: Ast_Statement 
}

Ast_Declaration_Statement :: struct {
	identifier: ^Ast_Identifier_Expression,
	expression: Ast_Expression
}

Ast_Procedure_Invocation :: struct {
	identifier: ^Ast_Identifier_Expression,
	parameter: Ast_Expression
}

Ast_Assignement_Statement :: struct {
	left: Ast_Expression,
	right: Ast_Expression
}

Ast_Block_Statement :: struct {
	statements: []Ast_Statement
}

Ast_Expression :: union {
	^Ast_Number_Expression,
	^Ast_Identifier_Expression,
	^Ast_Binary_Expression,
	^Ast_Literal_Expression,
	^Ast_Negate_Expression,
	^Ast_Parenthesis_Expression
}

Ast_Expression_Statement :: struct {
	expression: Ast_Expression
}

Ast_Negate_Expression :: struct {
	expression: Ast_Expression
}

Ast_Parenthesis_Expression :: struct {
	expression: Ast_Expression
}

Ast_Number_Expression :: struct {
	value: i32
}

Ast_Identifier_Expression :: struct {
	identifier: string
}

Ast_Binary_Expression :: struct {
	left: Ast_Expression,
	operator: Token,
	right: Ast_Expression
}

Ast_Literal_Expression :: struct {
	literal: Token
}

Parser :: struct {
	tokenizer: Tokenizer,
	lookahead: Token
}

Visitor :: struct {
	visit: proc(visitor: ^Visitor, node: Ast_Node, nesting: int) -> ^Visitor,
	data:  rawptr,
}


walk :: proc(v: ^Visitor, node: Ast_Node, nesting: int) {
	v->visit(node, nesting);

	nesting := nesting + 1

	switch n in node {
		case ^Ast_Procedure:
			for p in n.parameters{
				walk(v, p, nesting)
			}
			walk(v, n.body, nesting)
		case ^Ast_Parameter:
		case Ast_Statement:
			switch s in n{
				case ^Ast_If_Statement:
					walk(v, s.condition, nesting)
					walk(v, s.body, nesting)
				case ^Ast_Assignement_Statement:
					walk(v, s.left, nesting)
					walk(v, s.right, nesting)
				case ^Ast_Block_Statement:
					for statement in s.statements {
						walk(v, statement, nesting)
					}	
		        case ^Ast_Expression_Statement:
        			walk(v, s.expression, nesting)
    			case ^Ast_Declaration_Statement:
    				walk(v, s.expression, nesting)	
				case ^Ast_Procedure_Invocation:
					walk(v, s.parameter, nesting)		
			}
		case Ast_Expression: 
			switch e in n{
				case ^Ast_Binary_Expression:
					walk(v, e.left, nesting)
					walk(v, e.right, nesting)
				case ^Ast_Number_Expression:
				case ^Ast_Identifier_Expression:
				case ^Ast_Literal_Expression:
				case ^Ast_Parenthesis_Expression:
					walk(v, e.expression, nesting)
				case ^Ast_Negate_Expression:
					walk(v, e.expression, nesting)
			}
		case:
			fmt.printfln("%v doesn't match anything")
	}

}
