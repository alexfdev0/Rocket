# Global sect
SRC=.
LUAC=luac
# Unix sect
INSTALL_DIR=/usr/bin/rocketlang
EXECUTABLE=/usr/bin/rocket
# Mac sect
INSTALL_DIR_MAC=/usr/local/bin/rocketlang
EXECUTABLE_MAC=/usr/local/bin/rocket

.PHONY: clean

unix: $(SRC)/rocket.lua
	sudo mkdir -p $(INSTALL_DIR)
	sudo $(LUAC) -o $(INSTALL_DIR)/rocket.out $(SRC)/rocket.lua
	printf '#!/bin/sh\nexec lua $(INSTALL_DIR)/rocket.out "$$@"' | sudo tee $(EXECUTABLE) > /dev/null
	sudo mv $(SRC)/packages/*.lua /usr/bin/rocketlang/
	sudo chmod +x $(EXECUTABLE)

mac: $(SRC)/rocket.lua
	sudo mkdir -p $(INSTALL_DIR_MAC)
	sudo $(LUAC) -o $(INSTALL_DIR_MAC)/rocket.out $(SRC)/rocket.lua
	printf '#!/bin/sh\nexec lua $(INSTALL_DIR_MAC)/rocket.out "$$@"' | sudo tee $(EXECUTABLE_MAC) > /dev/null
	sudo mv $(SRC)/packages/*.lua /usr/local/bin/rocketlang/
	sudo chmod +x $(EXECUTABLE_MAC)
	
clean:
	sudo rm -rf $(INSTALL_DIR)
	sudo rm -f $(EXECUTABLE)