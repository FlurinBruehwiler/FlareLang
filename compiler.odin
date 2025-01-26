package compiler

import "core:fmt"

Local :: struct {
	name: string,
	depth: int
}

define_local :: proc(b: ^Block_Builder, name: string){
	b.locals[b.localCount] = Local {
		name = name,
		depth = 0
	}
	b.localCount += 1
}

resolve_local :: proc(b: ^Block_Builder, name: string) -> i16 {
	for i := b.localCount - 1; i >= 0; i -= 1 {
		if b.locals[i].name == name {
			return i16(i)
		}
	}
	return -1
}

compile_node :: proc(b: ^Block_Builder, node: Ast_Node){
	#partial switch n in node {
		case Ast_Expression:
			switch e in n {
				case ^Ast_Binary_Expression:
					compile_node(b, e.left)
					compile_node(b, e.right)
					
					#partial switch e.operator.kind {
						case .Add:
							block_add_opcode(b, .Add)
						case .Multiply:
							block_add_opcode(b, .Multiply)
					}
				case ^Ast_Number_Expression:
					block_add_push(b, e.value)
				case ^Ast_Identifier_Expression:
					idx := resolve_local(b, e.identifier)
					assert(idx != -1, "Local variable not found!")
					block_get_getlocal(b, idx)
				case ^Ast_Literal_Expression:
				case ^Ast_Parenthesis_Expression:
					compile_node(b, e.expression)
				case ^Ast_Negate_Expression:
			}
		case Ast_Statement:
			switch s in n {
				case ^Ast_Assignement_Statement:
					compile_node(b, s.right)
					local_identifier := s.left.(^Ast_Identifier_Expression)
					idx := resolve_local(b, local_identifier.identifier)
					block_set_local(b, idx)
				case ^Ast_Block_Statement:
					for statement in s.statements {
						compile_node(b, statement)
					}
				case ^Ast_Expression_Statement:
					compile_node(b, s.expression)
				case ^Ast_If_Statement:
				case ^Ast_Declaration_Statement:
					compile_node(b, s.expression)
					local_identifier := s.identifier.identifier
					define_local(b, local_identifier)
				case ^Ast_Procedure_Invocation:
					block_add_opcode(b, .Print)
			}
		case:
			fmt.printfln("%v", typeid_of(type_of(node)))
	}
}