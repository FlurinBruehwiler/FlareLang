package compiler

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:mem"

OpCode :: enum u8 {
	Push,
	Pop,
	Add,
	Subtract,
	Divide,
	Multiply,
	Call,
	Return,
	Set_Local,
	Get_Local
}

//takes byte code as textual representation and converts it to binary
assemble :: proc(code: string) -> []u8 {
	instructions := strings.split_lines(code)

	output: [dynamic]u8

	for i in instructions {

		parts := strings.split_n(strings.trim_space(i), " ", 2)

		switch parts[0] {
			case "PUSH":
				append(&output, u8(OpCode.Push))
				add_i32_from_string(&output, parts[1])
			case "ADD":
				append(&output, u8(OpCode.Add))
			case "SUBTRACT":
				append(&output, u8(OpCode.Subtract))
			case "DIVIDE":
				append(&output, u8(OpCode.Divide))
			case "MULTIPLY":
				append(&output, u8(OpCode.Multiply))
			case "CALL":
				append(&output, u8(OpCode.Call))
				add_i32_from_string(&output, parts[1])
			case "RETURN":
				append(&output, u8(OpCode.Return))
			case "POP":
				append(&output, u8(OpCode.Pop))
			case "GETLOCAL":
				append(&output, u8(OpCode.Get_Local))
				add_i16_from_string(&output, parts[1])
			case "SETLOCAL":
				append(&output, u8(OpCode.Get_Local))
				add_i16_from_string(&output, parts[1])
		}
	}

	return output[:]
}

add_i32_from_string :: proc(output: ^[dynamic]u8, str: string) {
	p1: int = strconv.atoi(strings.trim_space(str))
	append(output, ..mem.any_to_bytes(i32(p1)))
}

add_i16_from_string :: proc(output: ^[dynamic]u8, str: string) {
	p1: int = strconv.atoi(strings.trim_space(str))
	append(output, ..mem.any_to_bytes(i16(p1)))
}

//takes byte code as binary and converts it to textual representation
disassemble :: proc(code: []u8) -> string {

	sb := strings.builder_make()

	offset := 0

	for {
		len := disassemble_instruction(code, offset, &sb)
		if len == 0{
			break
		}

		offset += len
	}

	return strings.to_string(sb)
}


print_stack :: proc(vm: ^VM){
	for i := 0 ; i < vm.stack_top ; i += 1 {
		fmt.printfln("%v", vm.stack[i])
	}
}

print_instruction :: proc(code: []u8, offset: int) {
	builder := strings.builder_make()
	disassemble_instruction(code, offset, &builder)
	fmt.println(strings.to_string(builder))	
}

disassemble_instruction :: proc(code: []u8, offset: int, builder: ^strings.Builder) -> int {
	if offset >= len(code){
		return 0
	}

	strings.write_int(builder, offset)
	strings.write_string(builder, " ")

	ins := OpCode(code[offset])

	switch ins {
		case .Push:
			strings.write_string(builder, "PUSH ")
			write_integer(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 4
		case .Add:
			strings.write_string(builder, "ADD\n")
			return 1
		case .Subtract:
			strings.write_string(builder, "SUBTRACT\n")
			return 1
		case .Divide:
			strings.write_string(builder, "SUBTRACT\n")
			return 1
		case .Multiply:
			strings.write_string(builder, "SUBTRACT\n")
			return 1
		case .Call:
			strings.write_string(builder, "CALL ")
			write_integer(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 2
		case .Return:
			strings.write_string(builder, "RETURN\n")
			return 1
		case .Pop:
			strings.write_string(builder, "POP\n")
			return 1
		case .Get_Local:
			strings.write_string(builder, "GETLOCAL ")
			write_integer(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 2
		case .Set_Local:
			strings.write_string(builder, "SETLOCAL ")
			write_integer(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 2
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