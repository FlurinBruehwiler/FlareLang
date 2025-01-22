package compiler

import "core:fmt"
import "core:os"
import "core:unicode"

main :: proc(){

	code := "5*4+1*(2+3)"

	ast := parse(code, "example.fl")
	print(ast)
}

test_asm :: proc(){
	code := `
	PUSH 1
	PUSH 2
	ADD
	PUSH 3
	SUBTRACT
	CALL 8
	PUSH 69
	PUSH 420
	PUSH 14
	PUSH 10
	ADD
	RETURN
	`

	bin := assemble(code)
	fmt.printfln("Binary:\n%v", bin)

	vm := create_vm_from_block(Block {
		code = bin,
		data = nil
	})

	execute(vm)

	//disasm := disassemble(bin)
	//fmt.printfln("Text:\n%v", disasm)
}

test_ast :: proc(){
	file_path := "main.flare"
	data, success := os.read_entire_file_from_filename(file_path)

	if !success {
		panic("Error reading file")
	}

	stringData := string(data)

	node := parse(stringData, file_path)
	print(node)	
}

print_token :: proc(token: Token){
	fmt.printfln("%v: %v", token.kind, token.text)
}