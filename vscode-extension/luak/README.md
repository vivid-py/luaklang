# LuakLang Support

Syntax highlighting and language configuration for **luak**, a fast, statically-typed, lightweight programming language based on Lua.

## Features

This extension provides essential editor support for `.luak` files:

*   **Syntax Highlighting:** Colors for keywords (`let`, `if`, `while`), types (`int`, `string`), strings, numbers, and comments.
*   **Auto-closing Pairs:** Automatically closes brackets `{}`, `[]`, `()` and quotes `""`.
*   **Comment Toggling:** Quickly comment out lines using the `#` symbol (`Cmd+/` or `Ctrl+/`).
*   **Indentation Rules:** Automatically indents code blocks after `do` and `else`, and un-indents on `end`.

## Code Example

```luak
# LuakLang is statically typed and lua-based
import add from "summ"

let int a = 0
while a < 10 do
    let int b = add(a, 5)
    print(b)
    a = a + 1
end