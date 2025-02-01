package compiler

import "core:fmt"
import "core:mem"

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

compile_file :: proc(b: ^Block_Builder, file: ^Ast_File) {
	compile_node(b, file)
}

compile_node :: proc(b: ^Block_Builder, node: Ast_Node){
	#partial switch n in node {
		case ^Ast_File:

			//invoke main procedure
			procedure_invocation: Procedure_Invocation
			procedure_invocation.name = "Main"

			block_add_opcode_i32(b, .Call, 0) //call location is getting filled in later
			procedure_invocation.call_block_location = len(b.code) - 4
			append(&b.procedure_invocations, procedure_invocation)

			block_add_opcode(b, .Exit)

			for procedure in n.procedures {
				compile_node(b, procedure)
			}
			for invocation in b.procedure_invocations{
				definition := b.procedure_definitions[invocation.name]
				block_insert_i32(b, invocation.call_block_location, definition)
			}
		case ^Ast_Procedure:
			fmt.println("procedure")

			b.procedure_definitions[n.name.text] = i32(len(b.code))
			compile_node(b, n.body)
			block_add_opcode(b, .Return)
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
						case .Double_Equal:
							block_add_opcode(b, .Equal)
						case .Not_Equal:
							block_add_opcode(b, .Not_Equal)
						case .Greater:
							block_add_opcode(b, .Greater_Than)
						case .Lesser:
							block_add_opcode(b, .Lesser_Than)
						case .Greater_Equal:
							block_add_opcode(b, .Greater_Equal)
						case .Lesser_Equal:
							block_add_opcode(b, .Lesser_Equal)
						case:
							fmt.printfln("%v", e.operator.kind)
							assert(false, "Operator not supported")
					}
				case ^Ast_Number_Expression:
					block_add_opcode_i32(b, .Push, e.value)
				case ^Ast_Identifier_Expression:
					idx := resolve_local(b, e.identifier)
					assert(idx != -1, "Local variable not found!")
					block_add_opcode_i16(b, .Get_Local, idx)
				case ^Ast_Literal_Expression:
				case ^Ast_Parenthesis_Expression:
					compile_node(b, e.expression)
				case ^Ast_Negate_Expression:
				case ^Ast_Procedure_Invocation_Expression:
					procedure_invocation: Procedure_Invocation
					procedure_invocation.name = e.identifier.identifier

					for parameter in e.parameters {
						compile_node(b, parameter)
					}

					if e.identifier.identifier == "Print" {
						block_add_opcode(b, .Print)
					}else{
						block_add_opcode_i32(b, .Call, 0) //call location is getting filled in later
						procedure_invocation.call_block_location = len(b.code) - 4
						append(&b.procedure_invocations, procedure_invocation)

						//todo, remove parameters in a single instruction, currently this is a huge waste..
						for parameter in e.parameters { 
							block_add_opcode(b, .Pop)
						}	
					}
			}
		case Ast_Statement:
			switch s in n {
				case ^Ast_Assignement_Statement:
					compile_node(b, s.right)
					local_identifier := s.left.(^Ast_Identifier_Expression)
					idx := resolve_local(b, local_identifier.identifier)
					block_add_opcode_i16(b, .Set_Local, idx)
				case ^Ast_Block_Statement:
					for statement in s.statements {
						compile_node(b, statement)
					}
				case ^Ast_Expression_Statement:
					compile_node(b, s.expression)
				case ^Ast_If_Statement:
					compile_node(b, s.condition)
					
					if_jump_info := block_add_jump(b, .Jump_If_False)
					
					compile_node(b, s.body)

					else_jump_info: Jump_Info
					if s.else_statement != nil {
						else_jump_info = block_add_jump(b, .Jump)
					}
					
					block_set_jump_location(b, if_jump_info)

					if s.else_statement != nil{
						compile_node(b, s.else_statement)
						block_set_jump_location(b, else_jump_info)
					}

				case ^Ast_Declaration_Statement:
					compile_node(b, s.expression)
					local_identifier := s.identifier.identifier
					define_local(b, local_identifier)
				case ^Ast_For_Statement:

					for_start := len(b.code)

					compile_node(b, s.condition)

					jump_info := block_add_jump(b, .Jump_If_False)

					compile_node(b, s.body)
					block_add_opcode_i32(b, .Jump, -i32(len(b.code) + 5 - for_start))

					block_set_jump_location(b, jump_info)
			}
		case:
			fmt.printfln("%v", typeid_of(type_of(node)))
	}
}