package compiler

import "core:fmt"
import "core:slice"
import "core:log"

//bytecode info
Block :: struct {
	code: []u8,
	data: []u8
}

//vm runtime info
VM :: struct {
	block: ^Block,
	ip: int,
	base_pointer: int, //the base of the current procedure
	stack: []i32,
	stack_top: int
}

create_vm_from_block :: proc(block: ^Block) -> ^VM{
	vm, _ := new(VM)
	vm.stack = make([]i32, 250)
	vm.block = block
	return vm
}

execute :: proc(vm: ^VM){
	for vm.ip < len(vm.block.code) {
		//todo(fbr): only print while debugging -- add comp time if
		//fmt.println("----------------")
		//print_instruction(vm.block.code, vm.ip)

		switch OpCode(read_byte(vm)){
			case .Push:
				push(vm, read_i32(vm))
			case .Exit:
				return
			case .Add:
				push(vm, pop(vm) + pop(vm))
			case .Subtract:
				push(vm, pop(vm) - pop(vm))
			case .Divide:
				push(vm, pop(vm) / pop(vm))
			case .Multiply:
				push(vm, pop(vm) * pop(vm))
			case .Call:
				new_ip := int(read_i32(vm)) //jump
				push(vm, i32(vm.ip)) //push return address
				push(vm, i32(vm.base_pointer)) //push current base pointer
				vm.ip = new_ip
				vm.base_pointer = vm.stack_top
			case .Return:
				vm.stack_top = vm.base_pointer //pop off all locals
				vm.base_pointer = int(pop(vm)) //restore base pointer
				vm.ip = int(pop(vm)) //jump to return address
			case .Pop:
				pop(vm)
			case .Set_Local:
				slot := read_i16(vm)
				vm.stack[slot] = pop(vm)
			case .Get_Local:
				slot := read_i16(vm)
				push(vm, vm.stack[slot])
			case .Print:
				parameter := pop(vm)
				log.logf(.Info, "%v\n", parameter)
			case .Jump_If_False:
				jumpOffset := read_i32(vm)
				condition := pop(vm)
				if condition == 0 {
					vm.ip += int(jumpOffset)
				}
			case .Jump:
				vm.ip += int(read_i32(vm))
			case .Equal:
				if pop(vm) == pop(vm){
					push(vm, 1)
				}else{
					push(vm, 0)
				}
			case .Not_Equal:
				if pop(vm) != pop(vm){
					push(vm, 1)
				}else{
					push(vm, 0)
				}
			case .Greater_Than:
				if pop(vm) > pop(vm){
					push(vm, 1)
				}else{
					push(vm, 0)
				}
			case .Lesser_Than:
				if pop(vm) < pop(vm){
					push(vm, 1)
				}else{
					push(vm, 0)
				}
			case .Greater_Equal:
				if pop(vm) >= pop(vm){
					push(vm, 1)
				}else{
					push(vm, 0)
				}
			case .Lesser_Equal:
				if pop(vm) <= pop(vm){
					push(vm, 1)
				}else{
					push(vm, 0)
				}
		}

		//print_stack(vm)
	}
}

push :: #force_inline proc (vm: ^VM, value: i32){
	vm.stack[vm.stack_top] = value;
	vm.stack_top += 1
}

pop :: #force_inline proc (vm: ^VM) -> i32 {
	val := vm.stack[vm.stack_top-1]
	vm.stack_top -= 1
	return val
}

read_byte :: #force_inline proc(vm: ^VM) -> u8 {
	val := vm.block.code[vm.ip]
	vm.ip+=1
	return val
} 

read_i16 :: #force_inline proc(vm: ^VM) -> i16 {
	val := (transmute(^i16)&vm.block.code[vm.ip])^
	vm.ip+=2
	return val
}

read_i32 :: #force_inline proc(vm: ^VM) -> i32 {
	val := (transmute(^i32)&vm.block.code[vm.ip])^
	vm.ip+=4
	return val
}