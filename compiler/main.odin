package compiler

import "core:fmt"
import "core:os"
import "core:unicode"
import "core:unicode/utf8"

main :: proc(){

	file_path := "main.flare"
	data, success := os.read_entire_file_from_filename(file_path)

	if !success {
		panic("Error reading file")
	}

	stringData := string(data)

	parse(stringData, file_path)
}

print_token :: proc(token: Token){
	fmt.printfln("%v: %v", token.kind, token.text)
}