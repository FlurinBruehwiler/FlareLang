package compiler

import "core:fmt"


print :: proc(node: Ast_Node){
	visitor := Visitor {
		visit = print_visit
	}

	walk(&visitor, node)
}

print_visit :: proc(visitor: ^Visitor, node: Ast_Node) -> ^Visitor {
	fmt.printfln("%v", node)

	return visitor
}