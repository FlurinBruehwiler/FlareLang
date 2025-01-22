package compiler

compile_expression :: proc(b: ^Block_Builder, expression: Ast_Expression){
	switch e in expression {
		case ^Ast_Binary_Expression:
			compile_expression(b, e.left)
			compile_expression(b, e.right)
			
			#partial switch e.operator.kind {
				case .Add:
					block_add_add(b)
				case .Multiply:
					block_add_multiply(b)
			}
		case ^Ast_Number_Expression:
			block_add_push(b, e.value)
		case ^Ast_Identifier_Expression:
		case ^Ast_Literal_Expression:
		case ^Ast_Parenthesis_Expression:
		case ^Ast_Negate_Expression:
	}
}