package compiler

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:mem"

OpCode :: enum u8 {
	Return = 1,
	Add = 2,
	Subtract = 3
}

//takes byte code as textual representation and converts it to binary
assemble :: proc(code: string) -> []u8 {
	instructions := strings.split_lines(code)

	output: [dynamic]u8

	for i in instructions {

		parts := strings.split_n(strings.trim_space(i), " ", 2)

		switch parts[0] {
			case "RETURN":
				append(&output, u8(OpCode.Return))
			case "ADD":
				append(&output, u8(OpCode.Add))
				operands := strings.split_n(parts[1], ",", 2)

				add_bytes_from_string(&output, operands[0])
				add_bytes_from_string(&output, operands[1])
			case "SUBTRACT":
				append(&output, u8(OpCode.Subtract))
				operands := strings.split_n(parts[1], ",", 2)

				add_bytes_from_string(&output, operands[0])
				add_bytes_from_string(&output, operands[1])
		}
	}

	return output[:]
}

add_bytes_from_string :: proc(output: ^[dynamic]u8, str: string) {
	p1: int = strconv.atoi(strings.trim_space(str))
	append(output, ..mem.any_to_bytes(i32(p1)))
}

//takes byte code as binary and converts it to textual representation
disassemble :: proc(code: []u8) -> string {

	sb := strings.builder_make()

	offset := 0

	for {
		len := disassembleInstruction(code, offset, &sb)
		if len == 0{
			break
		}

		offset += len
	}

	return strings.to_string(sb)
}

disassembleInstruction :: proc(code: []u8, offset: int, builder: ^strings.Builder) -> int {
	if offset >= len(code){
		return 0
	}

	strings.write_int(builder, offset)
	strings.write_string(builder, " ")

	ins := OpCode(code[offset])

	switch ins {
		case .Return:
			strings.write_string(builder, "RETRUN\n")
			return 1
		case .Add:
			strings.write_string(builder, "ADD ")
			
			write_integer(builder, code[offset + 1:])
			strings.write_string(builder, ", ")
			write_integer(builder, code[offset + 1 + 4:])
			strings.write_string(builder, "\n")

			return 1 + 4 + 4
		case .Subtract:
			strings.write_string(builder, "SUBTRACT ")

			write_integer(builder, code[offset + 1:])
			strings.write_string(builder, ", ")
			write_integer(builder, code[offset + 1 + 4:])
			strings.write_string(builder, "\n")

			return 1 + 4 + 4
		case:
			fmt.printfln("Invalid instruction!!! %v", ins)
			return 0
	}

	return 0
}

write_integer :: proc(builder: ^strings.Builder, slice: []u8){
	p1 := transmute(^i32)&slice[0] 
	strings.write_int(builder, int(p1^))
}