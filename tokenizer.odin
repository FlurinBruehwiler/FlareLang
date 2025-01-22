package compiler

import "core:fmt"
import "core:os"
import "core:unicode"
import "core:unicode/utf8"

Tokenizer :: struct {
	offset: int,
	read_offset: int,
	src: string,
	ch: rune,
	path: string,
	line_offset: int,
	line_count: int,
}

Token :: struct {
	kind : Token_Kind,
	text: string,
	pos: Pos 
}

Pos :: struct {
	file: string,
	offset: int,
	line: int,
	column : int
}

Token_Kind :: enum {
	EOF,

	Identifier,
	Number,

	Add,
	Add_Equal,
	Increment,
	
	Subtract,
	Subtract_Equal,
	Decrement,

	Multiply,
	Multiply_Equal,

	Divide,
	Divide_Equal,

	Not,
	Not_Equal,

	Equal,
	Double_Equal,

	Greater,
	Greater_Equal,

	Lesser,
	Lesser_Equal,

	Semicolon,
	
	Open_Parenthesis,
	Close_Parenthesis,

	Open_Bracket,
	Close_Bracket,

	Open_Brace,
	Close_Brace,

	Keyword_Begin,
		If,
		Else,
		For,
		Return,
	Keyword_End,

	COUNT
}

tokens := [Token_Kind.COUNT]string {
	"EOF",

	"identifier",
	"number",

	"+",
	"+=",
	"++",

	"-",
	"-=",
	"--",

	"*",
	"*=",

	"/",
	"/=",

	"!",
	"!=",

	"=",
	"==",

	">",
	">=",

	"<",
	"<=",

	";",

	"(",
	")",

	"[",
	"]",

	"{",
	"}",

	"",
	"if",
	"else",
	"for",
	"return",
	""
}

create_tokenizer :: proc(content: string, file_path: string) -> Tokenizer {
	t := Tokenizer {
		path = file_path,
		src = content
	}

	advance_rune(&t)

	return t
}

scan :: proc(t: ^Tokenizer) -> Token{
	skip_whitespace(t)

	offset := t.offset

	kind: Token_Kind
	lit : string
	pos := offset_to_pos(t)

	ch := t.ch

	if is_letter(ch) {
		lit := scan_identifier(t)
		kind = .Identifier
		check_keyword: if len(lit) > 1 {
			for i in Token_Kind.Keyword_Begin ..= Token_Kind.Keyword_End {
				if lit == tokens[i] {
					kind = Token_Kind(i)
					break check_keyword
				}
			}
			break check_keyword
		}
	}else if ch >= '0' && ch <= '9'{
		lit = scan_number(t)
		kind = .Number
	}else{
		last := ch
		advance_rune(t)
		ch = t.ch
		switch last {
			case -1:
				kind = .EOF
			case '+':
				kind = .Add
				if t.ch == '=' {
					advance_rune(t)
					kind = .Add_Equal
				}else if ch == '+'{
					advance_rune(t)
					kind = .Increment
				}
			case '-':
				kind = .Subtract
				if ch == '=' {
					advance_rune(t)
					kind = .Subtract_Equal
				}else if ch == '-'{
					advance_rune(t)
					kind = .Decrement
				}
			case '*':
				kind = .Multiply
				if ch == '='{
					kind = .Multiply_Equal
				}
			case '/':
				kind = .Divide
				if ch == '='{
					kind = .Divide_Equal
				}
			case '!':
				kind = .Not
				if ch == '='{
					advance_rune(t)
					kind = .Not_Equal
				}
			case '=':
				kind = .Equal
				if ch == '='{
					advance_rune(t)
					kind = .Double_Equal
				}
			case '<':
				kind = .Greater
				if t.ch == '='{
					advance_rune(t)
					kind = .Greater_Equal
				}
			case '>':
				kind = .Lesser
				if t.ch == '='{
					advance_rune(t)
					kind = .Lesser_Equal
				}
			case ';':kind = .Semicolon
			case '(': kind = .Open_Parenthesis
			case ')': kind = .Close_Parenthesis
			case '[': kind = .Open_Bracket
			case ']': kind = .Close_Bracket
			case '{': kind = .Open_Brace
			case '}': kind = .Close_Brace
		}
	}

	return Token{
			kind = kind,
			text = string(t.src[offset : t.offset]),
			pos = pos
		}
}

scan_number :: proc(t: ^Tokenizer) -> string {
	offset := t.offset

	for t.ch >= '0' && t.ch <= '9' || t.ch == '_' {
		advance_rune(t)
	}

	return string(t.src[offset : t.offset])
}

scan_identifier :: proc(t: ^Tokenizer) -> string{

	offset := t.offset

	for is_letter(t.ch) {
		advance_rune(t)
	}

	return string(t.src[offset : t.offset])
}

skip_whitespace :: proc(t: ^Tokenizer){
	for {
		switch t.ch {
			case ' ', '\t', '\r', '\n':
				advance_rune(t)
			case:
				return
		}
	}
}

offset_to_pos :: proc(t: ^Tokenizer) -> Pos{
	return Pos {
		file = t.path,
		offset = t.offset,
		line = t.line_count,
		column = t.offset - t.line_offset + 1
	}
}

advance_rune :: proc(t: ^Tokenizer){
	if t.read_offset <= len(t.src){
		t.offset = t.read_offset

		r, w := utf8.decode_rune_in_string(t.src[t.read_offset:])
		t.read_offset += w
		t.ch = r
	}else{
		t.ch = -1
	}
}

is_letter :: proc(r: rune) -> bool {
	return unicode.is_letter(r)
}