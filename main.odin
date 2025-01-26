package compiler

import "core:fmt"
import "core:os"
import "core:unicode"
import "base:runtime"
import "core:debug/trace"

main :: proc(){
/*
	trace.init(&global_trace_ctx)
	defer trace.destroy(&global_trace_ctx)
	context.assertion_failure_proc = debug_trace_assertion_failure_proc
*/

	code := `
	{
		var x = 1;
		x = x + 1;
		print(x);
	}
	`

	ast := parse(code, "example.fl")
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

test_asm :: proc(){
	code := `
	PUSH 1
	PUSH 2
	PUSH 3
	MULTIPLY
	ADD
	`

	bin := assemble(code)
	fmt.printfln("Binary:\n%v", bin)

	block := Block {
		code = bin,
		data = nil
	}
	vm := create_vm_from_block(&block)

	execute(vm)

	//disasm := disassemble(bin)
	//fmt.printfln("Text:\n%v", disasm)
}

test_ast :: proc(){
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