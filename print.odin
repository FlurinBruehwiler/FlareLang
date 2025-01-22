package compiler

import "core:fmt"
import "core:strings"


print :: proc(node: Ast_Node){
	visitor := Visitor {
		visit = print_visit
	}

	walk(&visitor, node, 0)
}

print_visit :: proc(visitor: ^Visitor, node: Ast_Node, nesting: int) -> ^Visitor {
	fmt.printfln("%v%v", strings.repeat(" ", nesting * 4), node)

	return visitor
}