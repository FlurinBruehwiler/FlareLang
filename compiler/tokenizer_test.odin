package compiler

import "core:testing"
import "core:strings"
import "core:fmt"
import "core:bytes"
import "core:os"

@(test)
basic_procedure :: proc(t: ^testing.T) {

    stringData := `
void Test(int i){
    if(i < 1){
        print(i++)
    }
}
    `

    tokenizer := create_tokenizer(stringData, "main.flare")


    expected := `Identifier: void
Identifier: Test
Open_Parenthesis: (
Identifier: int
Identifier: i
Close_Parenthesis: )
Open_Brace: {
Identifier: if
Open_Parenthesis: (
Identifier: i
Greater: <
Number: 1
Close_Parenthesis: )
Open_Brace: {
Identifier: print
Open_Parenthesis: (
Identifier: i
Increment: ++
Close_Parenthesis: )
Close_Brace: }
Close_Brace: }
EOF:
`

    builder := strings.builder_make()

    for {
        token := scan(&tokenizer)

        fmt.sbprintfln(&builder, "%v: %v", token.kind, token.text)

        if token.kind == .EOF {
            break
        }
    }

    actual := strings.to_string(builder)

    write_string_to_file("expected.txt", expected)
    write_string_to_file("actual.txt", actual)

    testing.expect(t, strings.equal_fold(expected, actual))
}

write_string_to_file :: proc(file: string, content: string){
    handle, error := os.open(file, os.O_WRONLY)
    defer os.close(handle)

    os.write_string(handle, content)
}