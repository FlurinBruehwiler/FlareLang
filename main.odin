package compiler

import "core:fmt"
import "core:os"
import "core:unicode"
import "base:runtime"
import "core:log"
import "core:debug/trace"
import "core:path/filepath"
import vmem "core:mem/virtual"

console_log :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location){
	fmt.print(text)
}

//to run the main.fl use this:
// odin run . -- main.fl

main :: proc(){
	//trace.init(&global_trace_ctx)
	//defer trace.destroy(&global_trace_ctx)
	//context.assertion_failure_proc = debug_trace_assertion_failure_proc

	arena :vmem.Arena
	err := vmem.arena_init_growing(&arena)
	assert(err == nil)
	allocator := vmem.arena_allocator(&arena)
	context.allocator = allocator
	defer free_all()

	context.logger.procedure = console_log

	assert(len(os.args) > 1, "Compiler needs a file as an argument")

	content, err2 := os.read_entire_file(os.args[1])

	_, file_name := filepath.split(os.args[1])

	code := string(content)

	ast := parse(code, file_name)
	print(ast)
	fmt.println("--------------")

	block_builder := make_block_builder()

	compile_node(block_builder, ast)

	block := block_build(block_builder)

	disasm := disassemble(block.code)
	fmt.println(disasm)
	fmt.println("--------------")


	vm := create_vm_from_block(block)
	execute(vm)

}

global_trace_ctx: trace.Context

debug_trace_assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> ! {
	runtime.print_caller_location(loc)
	runtime.print_string(" ")
	runtime.print_string(prefix)
	if len(message) > 0 {
		runtime.print_string(": ")
		runtime.print_string(message)
	}
	runtime.print_byte('\n')

	ctx := &global_trace_ctx
	if !trace.in_resolve(ctx) {
		buf: [64]trace.Frame
		runtime.print_string("Debug Trace:\n")
		frames := trace.frames(ctx, 1, buf[:])
		for f, i in frames {
			fl := trace.resolve(ctx, f, context.temp_allocator)
			if fl.loc.file_path == "" && fl.loc.line == 0 {
				continue
			}
			runtime.print_caller_location(fl.loc)
			runtime.print_string(": ")
			runtime.print_string(fl.procedure)
			runtime.print_string(" - frame ")
			runtime.print_int(i)
			runtime.print_byte('\n')
		}
	}
	runtime.trap()
}