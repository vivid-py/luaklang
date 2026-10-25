#!/bin/bash

# Кольори для гарного виводу
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== LuakLang Installer ===${NC}"

# 1. Перевіряємо, чи встановлена Lua
if ! command -v lua &> /dev/null; then
    echo -e "${RED}Error: Lua is not installed!${NC}"
    echo "Please install Lua first (e.g., 'brew install lua' on macOS or 'sudo apt install lua5.4' on Ubuntu)."
    exit 1
fi
echo -e "${GREEN}[OK] Lua is installed.${NC}"

# 2. Робимо файл 'luak' виконуваним
if [ -f "luak" ]; then
    chmod +x luak
    echo -e "${GREEN}[OK] Made 'luak' executable.${NC}"
else
    echo -e "${RED}Error: 'luak' wrapper file not found!${NC}"
    exit 1
fi

# 3. Створюємо симлінк у папці, яка є в PATH
INSTALL_DIR="$HOME/.local/bin"
# Якщо папки немає, створюємо її
mkdir -p "$INSTALL_DIR"

# Створюємо символічне посилання
ln -sf "$(pwd)/luak" "$INSTALL_DIR/luak"
echo -e "${GREEN}[OK] Created symlink in $INSTALL_DIR${NC}"

# 4. Перевіряємо, чи $INSTALL_DIR є в PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH.${NC}"
    echo -e "Please add this line to your ~/.zshrc or ~/.bashrc:"
    echo -e "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo -e "Then restart your terminal or run: source ~/.zshrc"
else
    echo -e "${GREEN}[OK] $INSTALL_DIR is already in your PATH.${NC}"
fi

echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "You can now run your code from anywhere by typing:"
echo -e "  ${YELLOW}luak main.luak${NC}"