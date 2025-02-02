package compiler

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:mem"

OpCode :: enum u8 {
	Push,
	Pop,
	Exit,
	Add,
	Subtract,
	Divide,
	Multiply,
	Call,
	Return,
	Return_Value,
	Set_Local,
	Get_Local,
	Swap,
	Print,
	Jump_If_False,
	Jump,
	Equal,
	Not_Equal,
	Lesser_Than,
	Greater_Than,
	Lesser_Equal,
	Greater_Equal
}

Block_Builder :: struct {
	code: [dynamic]u8,
	data: [dynamic]u8,

	locals: []Local,
	local_count: i16,

	procedure_definitions: map[string]i32,
	procedure_invocations: [dynamic]Procedure_Invocation
}

Procedure_Invocation :: struct {
	name: string,
	call_block_location: int
}

make_block_builder :: proc() -> ^Block_Builder{
	n, _ := new(Block_Builder)
	n.code = make([dynamic]u8)
	n.data = make([dynamic]u8)
	n.locals = make([]Local, 100)

	n.procedure_definitions = make(map[string]i32)
	n.procedure_invocations = make([dynamic]Procedure_Invocation)

	return n
}

block_add_opcode :: proc(b: ^Block_Builder, op_code: OpCode){
	append(&b.code, u8(op_code))
}

block_add_opcode_i16 :: proc(b: ^Block_Builder, op_code: OpCode, arg: i16){
	append(&b.code, u8(op_code))
	append(&b.code, ..mem.any_to_bytes(arg))
}

block_add_opcode_i32 :: proc(b: ^Block_Builder, op_code: OpCode, arg: i32){
	append(&b.code, u8(op_code))
	append(&b.code, ..mem.any_to_bytes(arg))
}

Jump_Info :: struct {
	instructionLocation: int,
	jumpStartLocation: int
}

block_add_jump :: proc(b: ^Block_Builder, op_code: OpCode) -> Jump_Info{
	append(&b.code, u8(op_code))

	startLocation := len(b.code)
	append(&b.code, ..mem.any_to_bytes(i32(0)))
	startLocation2 := len(b.code)
	
	return Jump_Info {
		instructionLocation = startLocation,
		jumpStartLocation = startLocation2
	}
}

block_insert_i16 :: proc(b: ^Block_Builder, start_location: int, value: i16){
	copy(b.code[start_location:], mem.any_to_bytes(value))
}

block_insert_i32 :: proc(b: ^Block_Builder, start_location: int, value: i32){
	copy(b.code[start_location:], mem.any_to_bytes(value))
}

block_set_jump_location :: proc(b: ^Block_Builder, jump_info: Jump_Info){
	copy(b.code[jump_info.instructionLocation:], mem.any_to_bytes(i32(len(b.code) - jump_info.jumpStartLocation)))
}

block_build :: proc(b: ^Block_Builder) -> ^Block{
	n, _ := new(Block)
	n.code = b.code[:]
	n.data = b.data[:]
	return n
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
			case "EXIT":
				append(&output, u8(OpCode.Exit))
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
			case "RETURNVALUE":
				append(&output, u8(OpCode.Return))
			case "POP":
				append(&output, u8(OpCode.Pop))
			case "GETLOCAL":
				append(&output, u8(OpCode.Get_Local))
				add_i16_from_string(&output, parts[1])
			case "SETLOCAL":
				append(&output, u8(OpCode.Get_Local))
				add_i16_from_string(&output, parts[1])
			case "SWAP":
				append(&output, u8(OpCode.Swap))
				add_i16_from_string(&output, parts[1])
			case "PRINT":
				append(&output, u8(OpCode.Print))
			case "JMPIFFALSE":
				append(&output, u8(OpCode.Jump_If_False))
				add_i32_from_string(&output, parts[1])
			case "JUMP":
				append(&output, u8(OpCode.Jump))
				add_i32_from_string(&output, parts[1])
			case "EQUAL":
				append(&output, u8(OpCode.Equal))
			case "NOTEQUAL":
				append(&output, u8(OpCode.Not_Equal))
			case "GREATHERTHAN":
				append(&output, u8(OpCode.Greater_Than))
			case "LESSERTHAN":
				append(&output, u8(OpCode.Lesser_Than))
			case "GREATEREQUALS":
				append(&output, u8(OpCode.Greater_Equal))
			case "LESSEREQUALS":
				append(&output, u8(OpCode.Lesser_Equal))
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
			write_i32(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 4
		case .Exit:
			strings.write_string(builder, "EXIT\n")
			return 1
		case .Add:
			strings.write_string(builder, "ADD\n")
			return 1
		case .Subtract:
			strings.write_string(builder, "SUBTRACT\n")
			return 1
		case .Divide:
			strings.write_string(builder, "DIVIDE\n")
			return 1
		case .Multiply:
			strings.write_string(builder, "MULTIPLY\n")
			return 1
		case .Call:
			strings.write_string(builder, "CALL ")
			write_i32(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 4
		case .Return:
			strings.write_string(builder, "RETURN\n")
			return 1
		case .Return_Value:
			strings.write_string(builder, "RETURNVALUE\n")
			return 1
		case .Pop:
			strings.write_string(builder, "POP\n")
			return 1
		case .Get_Local:
			strings.write_string(builder, "GETLOCAL ")
			write_i16(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 2
		case .Set_Local:
			strings.write_string(builder, "SETLOCAL ")
			write_i16(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 2
		case .Swap:
			strings.write_string(builder, "SWAP ")
			write_i16(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 2
		case .Print:
			strings.write_string(builder, "PRINT\n")
			return 1
		case .Jump_If_False:
			strings.write_string(builder, "JMPIFFALSE ")
			write_i32(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 4
		case .Jump:
			strings.write_string(builder, "JUMP ")
			write_i32(builder, code[offset + 1:])
			strings.write_string(builder, "\n")
			return 1 + 4
		case .Equal:
			strings.write_string(builder, "EQUAL\n")
			return 1
		case .Not_Equal:
			strings.write_string(builder, "NOTEQUAL\n")
			return 1
		case .Greater_Equal:
			strings.write_string(builder, "GREATHEREQUAL\n")
			return 1
		case .Lesser_Equal:
			strings.write_string(builder, "LESSEREQUAL\n")
			return 1
		case .Greater_Than:
			strings.write_string(builder, "GREATERTHAN\n")
			return 1
		case .Lesser_Than:
			strings.write_string(builder, "LESSERTHAN\n")
			return 1
		case:
			fmt.printfln("Invalid instruction!!! %v", ins)
			return 0
	}

	return 0
}

write_i16 :: proc(builder: ^strings.Builder, slice: []u8){
	p1 := transmute(^i16)&slice[0] 
	strings.write_int(builder, int(p1^))
}

write_i32 :: proc(builder: ^strings.Builder, slice: []u8){
	p1 := transmute(^i32)&slice[0] 
	strings.write_int(builder, int(p1^))
}