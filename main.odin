package compiler

import "core:fmt"
import "core:os"
import "core:unicode"

main :: proc(){

	test_asm()
}

test_asm :: proc(){
	code := `
	RETURN
	ADD 1, 2
	SUBTRACT 42, 11
	`

	bin := assemble(code)
	fmt.printfln("Binary:\n%v", bin)


	disasm := disassemble(bin)
	fmt.printfln("Text:\n%v", disasm)
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