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

	//Statements
	^Ast_If_Statement,
	^Ast_Assignement_Statement,
	^Ast_Block_Statement,

	//Expressions
	^Ast_Number_Expression,
	^Ast_Identifier_Expression,
	^Ast_Binary_Expression,
	^Ast_Literal_Expression
}

Ast_Statement :: union {
	^Ast_If_Statement,
	^Ast_Assignement_Statement,
	^Ast_Block_Statement
}

Ast_If_Statement :: struct {
	condition: Ast_Expression,
	body: Ast_Statement
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
	^Ast_Literal_Expression
}

Ast_Number_Expression :: struct {
	value: int
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
	visit: proc(visitor: ^Visitor, node: Ast_Node) -> ^Visitor,
	data:  rawptr,
}


walk :: proc(v: ^Visitor, node: Ast_Node) {
	v->visit(node);

	switch n in node {
		case ^Ast_Procedure:
			for p in n.parameters{
				walk(v, p)
			}
			walk(v, n.body)
		case ^Ast_Parameter:
		case Ast_Statement:
			switch s in n{
				case ^Ast_If_Statement:
					walk(v, s.condition)
					walk(v, s.body)
				case ^Ast_Assignement_Statement:
					walk(v, s.left)
					walk(v, s.right)
				case ^Ast_Block_Statement:
					for statement in s.statements {
						walk(v, statement)
					}						
			}
		case Ast_Expression: 
			switch e in n{
				case ^Ast_Binary_Expression:
					walk(v, e.left)
					walk(v, e.right)
				case ^Ast_Number_Expression:
				case ^Ast_Identifier_Expression:
				case ^Ast_Literal_Expression:
			}
		case ^Ast_Binary_Expression:
		case ^Ast_If_Statement: 
		case ^Ast_Assignement_Statement: 
		case ^Ast_Block_Statement: 
		case ^Ast_Number_Expression: 
		case ^Ast_Identifier_Expression: 
		case ^Ast_Literal_Expression:
		case:
			fmt.printfln("%v doesn't match anything")
	}

}
