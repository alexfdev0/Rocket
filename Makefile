ifeq ($(OS),Windows_NT)
	TARGET := win
else
	TARGET := unix
endif

# Global sect
SRC=.
LUAC=luac
# Unix sect
INSTALL_DIR=/usr/bin/rocketlang
EXECUTABLE=/usr/bin/rocket
# Windows sect
INSTALL_DIR_WIN=$(LOCALAPPDATA)\rocket
EXECUTABLE_WIN=$(INSTALL_DIR_WIN)\rocket.bat

.PHONY: all clean

all: $(TARGET)

unix: $(SRC)/rocket.lua
	sudo mkdir -p $(INSTALL_DIR)
	sudo $(LUAC) -o $(INSTALL_DIR)/rocket.out $(SRC)/rocket.lua
	echo '#!/bin/sh\nexec lua $(INSTALL_DIR)/rocket.out "$$@"' | sudo tee $(EXECUTABLE) > /dev/null
	sudo chmod +x $(EXECUTABLE)

windows: $(SRC)/rocket.lua
	@if not exist "$(INSTALL_DIR_WIN)" mkdir "$(INSTALL_DIR_WIN)"
	$(LUAC) -o "$(INSTALL_DIR_WIN)\rocket.out" $(SRC)/rocket.lua
	@echo @echo off > "$(EXECUTABLE_WIN)"
	@echo lua "$(INSTALL_DIR_WIN)\rocket.out" %%* >> "$(EXECUTABLE_WIN)"
	@echo Please add "$(INSTALL_DIR_WIN)" to your environment PATH variable to run Rocket from anywhere. (Requires shell restart)
	
clean:
	sudo rm -rf $(INSTALL_DIR)
	sudo rm -f $(EXECUTABLE)