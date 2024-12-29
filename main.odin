package compiler

import "core:fmt"
import "core:os"
import "core:unicode"

main :: proc(){

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