package compiler

import "core:fmt"
import "core:os"
import "core:unicode"

main :: proc(){

	code := "1+2*3"

	ast := parse(code, "example.fl")
	print(ast)

	block_builder := make_block_builder()

	compile_expression(block_builder, ast)

	block := block_build(block_builder)

	disasm := disassemble(block.code)
	fmt.println(disasm)

	vm := create_vm_from_block(block)
	execute(vm)
}

test_asm :: proc(){
	code := `
	PUSH 1
	PUSH 2
	PUSH 3
	MULTIPLY
	ADD
	`

	bin := assemble(code)
	fmt.printfln("Binary:\n%v", bin)

	block := Block {
		code = bin,
		data = nil
	}
	vm := create_vm_from_block(&block)

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