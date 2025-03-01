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
# MAc sect
INSTALL_DIR_MAC=/usr/local/bin/rocketlang
EXECUTABLE_MAC=/usr/local/bin/rocket
# Windows sect
INSTALL_DIR_WIN=$(LOCALAPPDATA)\rocket
EXECUTABLE_WIN=$(INSTALL_DIR_WIN)\rocket.bat

.PHONY: clean

unix: $(SRC)/rocket.lua
	sudo mkdir -p $(INSTALL_DIR)
	sudo $(LUAC) -o $(INSTALL_DIR)/rocket.out $(SRC)/rocket.lua
	echo '#!/bin/sh\nexec lua $(INSTALL_DIR)/rocket.out "$$@"' | sudo tee $(EXECUTABLE) > /dev/null
	sudo chmod +x $(EXECUTABLE)

mac: $(SRC)/rocket.lua
	sudo mkdir -p $(INSTALL_DIR_MAC)
	sudo $(LUAC) -o $(INSTALL_DIR_MAC)/rocket.out $(SRC)/rocket.lua
	echo '#!/bin/sh\nexec lua $(INSTALL_DIR_MAC)/rocket.out "$$@"' | sudo tee $(EXECUTABLE_MA) > /dev/null
	sudo chmod +x $(EXECUTABLE_MAC)
	
clean:
	sudo rm -rf $(INSTALL_DIR)
	sudo rm -f $(EXECUTABLE)