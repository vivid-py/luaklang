#  LuakLang

**A fast, lightweight, statically-typed programming language that transpiles to pure Lua.**

LuakLang is designed for developers who love the simplicity and portability of Lua, but crave the safety of static typing, modern syntax, and zero-dependency execution. Whether you are writing CLI tools, TUI applications, or game logic, `luak` compiles down to clean, highly-portable Lua code that runs anywhere.

##  Features

*    **Blazing Fast:** The compiler is written in pure Lua and starts in ~2 milliseconds. No heavy runtimes, no Node.js, no Python.
*    **Statically Typed:** Catch type errors at compile time, not runtime. No more `attempt to index a nil value`.
*    **Zero Dependencies:** The core compiler is a single Lua script. It runs anywhere a Lua VM exists.
*    **Modern Syntax:** Clean, keyword-driven syntax inspired by Python, Go, and Rust.
*    **Seamless Imports:** Native module system with dependency resolution.
*    **Editor Support:** Official VS Code extension for syntax highlighting and auto-completion.

##  Quick Start

### Prerequisites
All you need is a **Lua 5.3+** interpreter installed on your system.

### Compiling & Running

1. Clone the repository:
   ```bash
   git clone https://github.com/vivid-py/luaklang.git
   cd luaklang```

2.  Write your first program 
    ```luak
    # main.luak
    import math from "libs/math"

    let string name = "World"
    print("Hello, " + name + "!")

    let int result = math.add(5, 10)
    print("5 + 10 =", result)
    ```

3. Compile it and run using the **luak** compiler
    ```bash
    lua luak.lua main.luak
    ```
    *The compiler automatically resolves dependencies, type-checks the code, generates main.lua, and runs it!*

##  Language Syntax

**Variables and types**
    ```

    let int a = 10
    let float b = 2.5
    let string name = "vivid"
    let bool is_ready = true

    # Arrays (0-indexed)
    let [int] numbers = [10, 20, 30]

    # Structs
    let User user = { name: "vivid", age: 20 }
    print(user.name)

    ```
**Functions**
Functions are declared with *let* and parameters include types.

    ```
    let add(int a, int b) do
        return a + b
    end
    let greet(string name) do
        print("Hello, " + name)
    end
    ```

**Functions**
Create a file *libs/math.luak*:

    ```
    let add(int a, int b) do
        return a + b
    end
    return add 
    ```

Import it into *main file*:

    ```
    import add from "libs/math"
    print(add(2, 3))
    ```
## VS-code extension

We have an official extension for syntax highlighting!

1. Navigate to the vscode-extension folder.
2. Package the extension:
    ```
    npx @vscode/vsce package
    ```
3. Install the generated .vsix file in VS Code.

## Contributing
This language is in its early stages and growing fast. Any contributions, bug reports, or feature requests are highly welcome! Feel free to open an Issue or submit a Pull Request.



*Built with love and a mission to create a fast, simple, lightweight programming language.*

*Loving vivid-py*
