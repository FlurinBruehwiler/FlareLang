package compiler

//bytecode info
Block :: struct {
	code: []u8,
	data: []u8
}

//vm runtime info
VM :: struct {
	block: Block
	ip: int,
	stack: []i32,
	stack_top: int
}

execute :: proc(vm: ^VM){
	for {
		//todo(fbr): only print while debugging
		disassembleInstruction(vm.block.code, vm.ip)

		switch OpCode(read_byte(vm)){
			case .Push:
				push(vm, read_i32(vm))
			case .Add:
				push(vm, pop(vm) + pop(vm))
			case .Subtract:
				push(vm, pop(vm) - pop(vm))
		}
	}
}

print_stack :: proc(vm: ^VM){
	for i := 0 ; i < vm.stack_top ; i += 1 {
		fmt.printfln("%v", vm.stack[i])
	}
}

push :: #force_inline proc (vm: ^VM, value: i32){
	vm.stack[vm.stack_top] = value;
	vm.stack_top += 1
}

pop :: #force_inline proc (vm: ^VM) -> i32 {
	val := vm.stack[vm.stack_top]
	vm.stack_top -= 1
	return val
}

read_byte :: #force_inline proc(vm: ^VM) -> u8 {
	val := vm.block.code[vm.ip]
	vm.ip+=1
	return val
} 

read_i32 :: #force_inline proc(vm: ^VM) -> i32 {
	val := (transmute(^i32)&vm.block.code[vm.ip])^
	vm.ip+=4
	return val
}