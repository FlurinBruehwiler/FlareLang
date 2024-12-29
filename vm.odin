package compiler

VM :: struct {
	code: []u8
	ip: int
	stack: []i32
	stack_top: int
}

execute :: proc(vm: VM){
	for {
		switch OpCode(read_byte()){
			case .Return:
			case .Add:
				res := readi32() + readi32()
			case .Subtract:
				res := readi32() - readi32()
		}
	}
}

push :: (vm: VM, value: i32){
	vm.stack[vm.stack_top] = value;
	vm.stack_top += 1
}

pop :: (vm: VM) -> i32 {
	val := vm.stack[vm.stack_top]
	vm.stack_top -= 1
	return val
}

read_byte :: #force_inline proc(vm: VM) -> u8 {
	val := vm.code[vm.ip]
	vm.ip+=1
	return val
} 

read_i32 :: #force_inline proc(vm: VM) -> i32 {
	val := (transmute(^i32)&vm.code[vm.ip])^
	vm.ip+=4
	return val
}