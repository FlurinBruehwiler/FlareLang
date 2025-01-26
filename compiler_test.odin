package compiler

import "core:testing"
import "core:strings"
import "core:bytes"
import "core:os"
import "core:log"
import "base:runtime"
import vmem "core:mem/virtual"

@(test)
for_loop :: proc(t: ^testing.T) {

   	code := `
	{
		var x = 0;

		for(x < 5){
			print(x);
			x = x + 1;
		}

		print(20);
	}
	`

	output := run(code)
	expected := `0
1
2
3
4
20
`;

	testing.expect_value(t, output, expected)

	free_all(context.temp_allocator)
}

@(test)
if_else :: proc(t: ^testing.T) {

   	code := `
	{
		var x = 0;

		if(x < 5){
			print(x);
			x = x + 1;
		}else{
			print(40);
		}

		print(x);
	}
	`

	output := run(code)
	expected := `0
1
`;

	testing.expect_value(t, output, expected)

	free_all(context.temp_allocator)
}

@(test)
if_else_branch :: proc(t: ^testing.T) {

   	code := `
	{
		var x = 6;

		if(x < 5){
			print(x);
			x = x + 1;
		}else{
			print(40);
		}

		print(x);
	}
	`

	output := run(code)
	expected := `40
6
`;

	testing.expect_value(t, output, expected)

	free_all(context.temp_allocator)
}

@(test)
else_if :: proc(t: ^testing.T) {

   	code := `
	{
		var x = 6;

		if(x == 3){
			print(41);
		}else if (x == 6){
			print(42);
		}else{
			print(43);
		}

		print(x);
	}
	`

	output := run(code)
	expected := `42
6
`;

	testing.expect_value(t, output, expected)

	free_all(context.temp_allocator)
}

run :: proc(code: string) -> string {

	arena :vmem.Arena
	err := vmem.arena_init_growing(&arena)
	assert(err == nil)
	allocator := vmem.arena_allocator(&arena)
	context.allocator = allocator
	defer free_all()

	ast := parse(code, "example.fl")

	block_builder := make_block_builder()

	compile_node(block_builder, ast)

	block := block_build(block_builder)

	vm := create_vm_from_block(block)

	builder, _ := strings.builder_make(context.temp_allocator)

	context.logger.procedure = log_intercept;
	context.logger.data = &builder

	execute(vm)

	return strings.to_string(builder)
}

log_intercept :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location){
	builder := transmute(^strings.Builder)data
	strings.write_string(builder, text)
}