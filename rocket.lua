local variables = {
	[0x0] = { -- Global scope
		{"STD_SP", " ", true},
		{"True", true, true},
		{"False", false, true},
		{"null", nil, true},
		{"STD_SCOPE_ADDR", 0x0, true},
		{"STD_IS_ROBLOX", false, true},
		{"STD_BKSL", [[\]], true},
		{"STD_IS_NTFS", false, true},
	},
}

local functions = {}

local validsecondclass = {
	"=",
}

local validfirstclass = {
	-- General purpose functions
	"if",
	"function",
	"return",
	"call",
	"calc",
	"for",
	"require",
}

local fcBinds = {}

local errors = {
	[1] = "Unknown argument(s)",
	[2] = "Unknown global function",
	[3] = "If statement is not followed by Then after condition",
	[4] = "If statement is not closed by an End after function if then",
	[5] = "Equal operator not preceeded by variable name",
	[6] = "No condition to check for",
	[7] = "Function statement is not closed by an End after function code",
	[8] = "Unknown function",
	[9] = "Function informational section not closed by a Do",
	[10] = "No semicolon detected in instruction.",
	[11] = "File could not be read",
	[12] = "Not a valid number", 
	[13] = "Not a valid arithmetic operation",
	[14] = "Division by zero is not allowed",
	[15] = "String is either not opened or closed by quotes",
	[16] = "Not a valid variable",
	[17] = "Value not supplied",
	[18] = "Illegal comparison",
	[19] = "Do is not in the correct location for this type of for loop",
	[20] = "For loop is not closed by an End",
	[21] = "The all keyword shortcut is not allowed in this type of for loop",
	[22] = "Itr was not at the expected place in the for loop",
	[23] = "No variable name for itr in the for loop",
	[24] = "Variable is immutable",
	[25] = "Table was not closed by closing brace",
	[26] = "Out of scope space",
	[27] = "Low on scope space, consider freeing up unused scopes",
	[28] = "Operating in invalid scope",
	[29] = "Invalid scope",
	[30] = "Failed to get table inheritance tree. No higher scope variables will be auto-referenced.",
	[31] = "Scope out of range (Must be between 0x001 and 0xfff [12 bit])",
	[32] = "This function can only be called inside of a Roblox environment",
	[33] = "Cannot name variable to reserved keyword",
	[34] = "The return keyword cannot be used outside of a function",
	[35] = "This function can only be called outside of a Roblox environment",
	[36] = "Invalid package",
	[37] = "Failed to load package",
	[38] = "Too few arguments",
}

local scopes = {
	0x0,
}

local function throwNew(typeo, err, args)
	local etext = errors[err]
	if typeo == "warning" then
		print("Warning: " .. etext .. " " .. args .. " (Warning " .. tostring(err) .. ")")
	elseif typeo == "error" then
		if variables[0x0][6][2] == false then
			print("Error: " .. etext .. " " .. args .. " (Error " .. tostring(err) .. ")")
			os.exit(err)
		else
			error("Error: " .. etext .. " " .. args .. " (Error " .. tostring(err) .. ")")
		end
	end
end

local function checkArgs(expct, tokens)
	if #tokens > expct then
		local extras = ""
		for i = expct + 1, #tokens do
			if i == 4 then
				extras = extras .. tokens[i]
			else
				extras = extras .. ", " .. tokens[i]
			end
		end
		throwNew("warning", 1, extras)
		return false
	elseif #tokens < expct then
		throwNew("warning", 38, "")
		return false
	end
	return true
end

local function declareVariable(scope, name, value, immutable, override)
	scope = tonumber(scope)
	if not variables[scope] then
		throwNew("warning", 28, "")
		return
	end
	local alreadyassigned = false
	for i, variable in pairs(variables[scope]) do
		if type(variable) == "table" then
			if name == variable[1] then
				if variables[scope][i][3] ~= true or override == true then
					variables[scope][i][2] = value
					alreadyassigned = true
				else
					throwNew("warning", 24, "")
				end
			end
		end
	end
	for _, keyword in pairs(validfirstclass) do
		if name == keyword then
			throwNew("warning", 33, "")
		end
	end
	if alreadyassigned == false then
		local const = false
		if immutable == true then
			const = true
		end
		table.insert(variables[scope], {name, value, const})
	end
end

local function getValueFromVariable(variablename, scope, silent)
	local found = false
	if scope == nil then
		scope = 0x0
	end
	if variables[scope] then
		for _, variable in pairs(variables[scope]) do
			if type(variable) == "table" then
				local name = variable[1]
				local value = variable[2]
				if variablename == name then
					found = true
					return value
				end
			end
		end
	else
		if silent ~= true then
			throwNew("warning", 29, "'" .. variablename .. "'")
		end
		return nil
	end
	if found == false then
		-- Updated for lazy loading of variables
		local inheritance = variables[scope].inheritance
		local current = inheritance
		local value = nil
		
		while current do
			local found = nil
			for _, variable in pairs(variables[current]) do
				if variable[1] == variablename then
					found = variable[2]
					break
				end
			end
			if found ~= nil then
				return found
			end
			current = variables[current].inheritance
		end

		if silent ~= true then
			throwNew("warning", 16, "'" .. variablename .. "'")
		end
		return nil
	end
end

local interpret

local function parseInput(valstart, tokens, checkfor, allowderef, scope)
    --[[
    example: {"y", "=", "1", "+", "1"} (y = 1 in this istance)
    We need to parse it so it is {"y", "=", "2"}
    ]]
	if scope == nil then
		scope = 0x0
	end
	local function solve(fnum, op, lnum)
		if op == "+" then
			return fnum + lnum
		elseif op == "-" then
			return fnum - lnum
		elseif op == "*" then
			return fnum * lnum
		elseif op == "/" then
			if lnum == 0 then
				throwNew("warning", 14, "")
				return 0
			else
				return fnum / lnum
			end
		elseif op == "^" then
			return fnum ^ lnum
		elseif op == "=" then
			if fnum == lnum then
				return true
			else
				return false
			end
		end
	end
	-- Check for lone numbers
	if tonumber(tokens[valstart]) and valstart == #tokens then
		checkArgs(valstart, tokens)
		return tonumber(tokens[valstart])
	end
	-- Check for arithmetic operation
	local opsect = tokens[valstart + 1]
	if opsect == "+" or opsect == "-" or opsect == "*" or opsect == "/" or opsect == "^" or opsect == "<<" or opsect == "!=" then
		local fnum = tokens[valstart]
		local lnum = tokens[valstart + 2]
		-- Check type of arithmetic
		if opsect == "<<" then
			local fstr = tokens[valstart]
			local lstr = tokens[valstart + 2]

			fstr = parseInput(1, { fstr }, true, false, scope)
			lstr = parseInput(1, { lstr }, true, false, scope)

			return fstr .. lstr
		elseif opsect == "!=" then
			local fval = parseInput(1, { tokens[valstart] }, true, false, scope)
			local lval = parseInput(1, { tokens[valstart + 2] }, true, false, scope)

			if fval == lval then
				return false
			else
				return true
			end
		else
			-- Check for if they are numbers or variables   
			if tonumber(fnum) then
				fnum = tonumber(fnum)
			else
				if tonumber(getValueFromVariable(fnum, scope)) then
					fnum = tonumber(getValueFromVariable(fnum, scope))
				else
					throwNew("error", 12, "")
				end
			end
			if tonumber(lnum) then
				lnum = tonumber(lnum)
			else
				if tonumber(getValueFromVariable(lnum, scope)) then
					lnum = tonumber(getValueFromVariable(lnum, scope))
				else
					throwNew("error", 12, "")
				end
			end
			return solve(fnum, opsect, lnum)
		end

	end
	
	-- Check for functions
	for _, keyword in pairs(validfirstclass) do
		if tokens[valstart] == keyword then
			local text = ""
			for i = valstart, #tokens do
				if i == valstart then
					text = text .. tokens[i]
				else
					text = text .. " " .. tokens[i]
				end
			end
			text = text .. ";"
			local values = interpret(text, {definedScope = scope, returnReturnValue = true})
			return values.returnValue
		end
	end

	-- Check for strings
	if tokens[valstart] ~= "{" then
		for i = 1, #tokens do
			tokens[i] = string.gsub(tokens[i], [[\27]], "\27")
			tokens[i] = string.gsub(tokens[i], [[\n]], "\n")
			tokens[i] = string.gsub(tokens[i], [[\r]], "\r")
		end
		if valstart == #tokens then
			if string.find(tokens[valstart], '"') then
				local count = 0

				local startp = string.find(tokens[valstart], '"+', 1, false)
				local endp = string.find(tokens[valstart], '"+', 2, false)

				if startp ~= 1 then
					throwNew("error", 15, "")
				end

				if endp ~= #tokens[valstart] then
					throwNew("error", 15, "")
				end

				tokens[valstart] = tokens[valstart]:gsub('"', "")
			else
				if getValueFromVariable(tokens[valstart], scope, true) ~= nil then
					tokens[valstart] = getValueFromVariable(tokens[valstart], scope)
				else
					if allowderef ~= true then
						return nil
					else
						tokens[valstart] = getValueFromVariable(tokens[valstart], scope)
					end
				end
			end
			return tokens[valstart]
		else
			local valend = 0
			for i = valstart + 1, #tokens do
				if string.find(tokens[i], '"') then
					valend = i
					break
				end
			end
			if valend == 0 then
				throwNew("error", 15, "")
			end
			if not string.find(tokens[valstart], '"') then
				throwNew("error", 15, "")
			end
			tokens[valstart] = tokens[valstart]:gsub('"', "")
			tokens[valend] = tokens[valend]:gsub('"', "")
			local str = ""
			for i = valstart, valend do
				if i == valstart then
					str = str .. tokens[i]
				else
					str = str .. " " .. tokens[i]
				end
			end
			return str
		end
	end
	-- Check for lone variable
	if valstart == #tokens and checkfor == true then
		if getValueFromVariable(tokens[valstart], scope, true) then
			return getValueFromVariable(tokens[valstart], scope)
			-- If not then assume it is a string being passed and move it along.
		end
	end
end

local function compare(tokens, condstart, condend, scope)
	local format = 0
	if tokens[condstart + 1] == "=" then
		format = 1
	else
		format = 2
	end
	if format == 1 then
		local firsttokens = {}
		local secondtokens = {}
		local equalloc = 0

		for i = condstart, #tokens do
			if tokens[i] == "=" or tokens[i] == "!=" then
				equalloc = i
				break
			else
				table.insert(firsttokens, tokens[i])
			end
		end

		local firstres = parseInput(1, firsttokens, true, false, scope)

		if equalloc == 0 then
			throwNew("error", 18, "")
		end

		for i = equalloc + 1, condend do
			table.insert(secondtokens, tokens[i])
		end

		local secondres = parseInput(1, secondtokens, true, false, scope)

		if firstres == secondres then
			return true
		else
			return false
		end
	else
		local f = tokens[condstart]

		local restokens = {}
		local exptokens = {}
		local equalloc = 0
		local thenloc = condend + 1

		for i = condstart, #tokens do
			if tokens[i] == "=" or tokens[i] == "!=" then
				equalloc = i
				break
			else
				table.insert(restokens, tokens[i])
			end
		end

		local first = parseInput(1, restokens, true, false, scope)

		if equalloc == 0 then
			throwNew("error", 18, "")
		end

		for i = equalloc + 1, condend do
			table.insert(exptokens, tokens[i])
		end

		local second = parseInput(1, exptokens, true, false, scope)

		if first == second then
			return true
		else
			return false
		end
	end
end

local function scopeHandle(action, scope, current, silent)
	if action == "create" then
		if tonumber(scope) then
			if scope > 0xfff or scope < 0x001 then
				throwNew("error", 31, "")
			end
		end
		if #scopes >= 0xfff then
			throwNew("error", 26, "")
		end

		if 0xfff - #scopes <= 1000 then
			throwNew("warning", 27, "")
		end

		local gen
		while true do
			local found = false
			math.randomseed(os.time())
			gen = math.random(0x001, 0xfff)
			for i = 1, #scopes do
				if scopes[i] == gen then
					found = true
				end
			end
			if found == false then
				break
			end
		end

		local getInheritance
		getInheritance = function(child, modify)
			if child.inheritance ~= nil then
				for _, pair in pairs(variables[child.inheritance]) do
					if type(pair) == "table" then
						table.insert(modify, pair)
					end
				end
				getInheritance(variables[child.inheritance], modify)
			end
		end
		local sId = 0
		if tonumber(scope) then
			sId = tonumber(scope)
		else
			sId = gen
		end
		if variables[sId] == nil then
			variables[sId] = {}
		end
		variables[sId].inheritance = current
		-- getInheritance(variables[sId], variables[sId]) use lazy loading instead
		table.insert(scopes, scope)
		declareVariable(sId, "STD_SCOPE_ADDR", sId, true, true)
		return sId
	elseif action == "destroy" then
		for i = 1, #scopes do
			if i == scope then
				table.remove(scopes, i)
			end
		end
		variables[scope] = nil
	end
end

local function checkFile(filename)
	local file = io.open(filename, 'r')
	if file then
		file:close()
		return true
	else
		return false
	end
end

local function registerError(body)
	table.insert(errors, body)
	for i = 1, #errors do
		if errors[i] == body then
			return i
		end
	end
end

interpret = function(text, args)
	if args == nil then
		args = {}
	end

	if args.definedScope == nil then
		args.definedScope = 0x0
	end

	local tokens = {}

	local vdec = false
	local func = false

	-- Lexer

	for token in string.gmatch(text, "%S+") do
		table.insert(tokens, token)
	end

	local otherf = {}

	local splitloc = 0

	if tokens[1] == "//" then
		return
	end

	if tokens[1] == "if" or tokens[1] == "function" or tokens[1] == "for" then
		local depth = 0

		for i = 1, #tokens do
			if tokens[i] == "function" or tokens[i] == "if" or tokens[i] == "for" then
				depth = depth + 1
			elseif tokens[i] == "end;" then
				depth = depth - 1

				if depth == 0 then
					tokens[i] = tokens[i]:gsub(";", "")
					splitloc = i
					break
				end
			end
		end
	else
		for i = 1, #tokens do
			local token = tokens[i]
			if string.find(token, ";") then
				tokens[i] = tokens[i]:gsub(";", "")
				splitloc = i
				break    
			end
		end
	end

	if splitloc == 0 then
		throwNew("error", 10, "")
	end

	for i = splitloc + 1, #tokens do
		table.insert(otherf, tokens[i])
		tokens[i] = nil
	end

	-- Deciding which operation to do

	for i, firstclass in pairs(validfirstclass) do
		if tokens[1] == firstclass then
			func = true
		end
	end

	if func == false then
		for i, secondclass in pairs(validsecondclass) do
			if tokens[2] == secondclass then
				vdec = true
			end
		end
	end

	if func == false and vdec == false then
		throwNew("error", 2, "'" .. tokens[1] .. "'")
	end

	-- Func handler
	if func == true then
		local name = tokens[1]
		if name == "print" then
			local res = parseInput(2, tokens, true, false, args.definedScope)
			if res then
				print(res)
			end
		elseif name == "if" then
			-- if statement handling
			local thenloc = 0
			local endloc = 0
			for i = 2, #tokens do
				if tokens[i] == "then" then
					thenloc = i
					break
				end
			end

			if thenloc == 0 then
				throwNew("error", 3, "")
			end

			for i = thenloc + 1, #tokens do
				if tokens[i] == "end" then
					endloc = i
					break
				end
			end

			if endloc == 0 then
				throwNew("error", 4, "")
			end

			local condstart = tokens[2]
			local condend = tokens[thenloc - 1]

			local funcstart = tokens[thenloc + 1]
			local funcend = tokens[endloc - 1]

			if condstart == "=" then
				throwNew("error", 5, "")
			end

			local execFunc = function()
				local portion = ""
				for i = thenloc + 1, endloc - 1 do
					if i == thenloc + 1 then
						portion = portion .. tokens[i]
					else
						portion = portion .. " " .. tokens[i]
					end
				end
				local scope = scopeHandle("create", nil, args.definedScope)
				interpret(portion, {definedScope = scope})
				scopeHandle("destroy", scope)
			end

			if compare(tokens, 2, thenloc - 1, args.definedScope) then
				execFunc()
			end
		elseif name == "function" then
			local fname = tokens[2]
			local isend = false
			local portion = ""
			local args = {}

			if tokens[#tokens] ~= "end" then
				throwNew("error", 7, "")
			end

			if tokens[3] == "do" then
				for i = 4, #tokens do
					if tokens[i] ~= "end" then
						if i == 4 then
							portion = portion .. tokens[i]
						else
							portion = portion .. " " .. tokens[i]
						end
					end
				end
				functions[fname] = {portion, args}
			elseif tokens[3] == "args" then
				local doloc

				for i = 4, #tokens do
					if tokens[i] == "do" then
						doloc = i
						break
					else
						table.insert(args, tokens[i])
					end
				end

				local portion = ""

				for i = doloc + 1, #tokens do
					if i < #tokens then
						if i == doloc + 1 then
							portion = portion .. tokens[i]
						else
							portion = portion .. " " .. tokens[i]
						end
					end
				end

				functions[fname] = {portion, args}
			else
				throwNew("error", 9, "")
			end
		elseif name == "return" then
			if getValueFromVariable("STD_IN_FUNCTION", args.definedScope, true) == true then
				local toReturn = parseInput(2, tokens, true, false, args.definedScope)
				args.returnValue = toReturn
			else
				throwNew("error", 34, "")
			end
		elseif name == "call" then
			local fname = tokens[2]
			if functions[fname] then
				local args_ = functions[fname][2]
				local scope = scopeHandle("create", nil, args.definedScope)
				for i, arg in pairs(args_) do
					print(i)
					local argname = arg
					declareVariable(scope, argname, parseInput(1, { tokens[i + 2] }, true, false, args.definedScope), false)
				end
				declareVariable(scope, "STD_IN_FUNCTION", true, true, true)
				declareVariable(scope, "STD_FUNCTION_NAME", fname, true, true)
				declareVariable(scope, "STD_CALLING", args.definedScope, true, true)
				functions[fname][2].definedScope = scope
				local result = interpret(functions[fname][1], functions[fname][2])
				scopeHandle("destroy", scope)
				args.returnValue = result.returnValue
			else
				throwNew("warning", 8, fname)
			end
		elseif name == "for" then
            --[[
            For loop syntax:
            "for <number or 'all'> in <table> itr <variable to iterate over> do <code> end"
            "for <number> to <number> itr <variable> do <code> end"
            ]]
			local range = tokens[2]

			if range ~= "all" then
				range = parseInput(1, { tokens[2] }, true, false, args.definedScope)
			end

			local typeo = tokens[3]

			-- 'In' loops not implemented for now.
			if typeo == "to" then
				local doloc = tokens[7]
				local itr = tokens[5]
				local itrval = tokens[6]
				local funcstart = tokens[8]
				local max = parseInput(1, { tokens[4] }, true, false, args.definedScope)
				if not tonumber(max) then
					throwNew("error", 12, "")
				end
				if not tonumber(range) then
					if range == "all" then
						throwNew("error", 21, "")
					else
						throwNew("error", 12, "")
					end
				end

				if itr ~= "itr" then
					throwNew("error", 22, "")
				end

				if itrval == "do" then
					throwNew("error", 23, "")
				end

				if doloc ~= "do" then
					throwNew("error", 19, "")
				end

				if tokens[#tokens] ~= "end" then
					throwNew("error", 20, "")
				end

				local funcend = #tokens - 1

				local scope = scopeHandle("create", nil, args.definedScope)
				local function exec(inum, scope)
					local str = ""
					for i = 8, funcend do
						if i == 8 then
							str = str .. tokens[i]
						else
							str = str .. " " .. tokens[i]
						end
					end

					declareVariable(scope, itrval, inum)
					interpret(str, {definedScope = scope})
					declareVariable(scope, itrval, nil)
				end

				for i = range, max do
					exec(i, scope)
				end
				scopeHandle("destroy", scope)
			end
		elseif name == "wait" then
			local ttw = parseInput(1, { tokens[2] }, true, false, args.definedScope)
			if getValueFromVariable("STD_IS_ROBLOX") == true then
				wait(ttw)
			else
				local ntime = os.time() + ttw
				repeat until os.time() > ntime
			end
		elseif name == "list_all" then
			for scope_, scope in pairs(variables) do
				for _, variable in pairs(scope) do
					print("Name: " .. variable[1] .. ", value: " .. tostring(variable[2]) .. ", immutable: " .. tostring(variable[3]) .. ", scope: " .. tostring(scope_))
				end
			end
		elseif name == "require" then
			local name = parseInput(1, { tokens[2] }, true, false, args.definedScope)
			local package_ = nil

			if getValueFromVariable("STD_IS_ROBLOX") == false then
				local found = checkFile(name)
				
				if found == false then
					if getValueFromVariable("STD_IS_NTFS") == false then
						package.path = "/usr/bin/rocketlang/?.lua;/usr/local/bin/rocketlang/?.lua;" .. package.path
						found = checkFile("/usr/bin/rocketlang/" .. name)
						if found == false then
							found = checkFile("/usr/local/bin/rocketlang/" .. name)
						end
					else
						package.path = "C:\\rocket\\?.lua;" .. package.path
						found = checkFile("C:\\rocket\\" .. name)
					end
				end

				if found == false then
					throwNew("error", 11, name)
				end

				local package_name = string.gsub(name, ".lua", "")
				package_ = require(package_name)
			else
				local module_obj = assert(loadstring("return " .. name), "Provided module is nil")
				package_ = require(module_obj)
			end

			if (not package_.bundle) then
				throwNew("error", 36, name)
			end

			for i = 1, #package_.bundle do
				local pack = package_.bundle[i]
				table.insert(validfirstclass, pack.name)
				table.insert(fcBinds, {pack.name, pack})
			end
		else
			local package_ = nil
			for i = 1, #fcBinds do
				if fcBinds[i][1] == name then
					package_ = fcBinds[i][2]
					break
				end
			end
			if package_ == nil then
				throwNew("error", 37, name)
			end
			local result = package_.func({
				tokens = tokens,
				args = args,
				variables = variables,
				scopes = scopes,
				throwNew = throwNew, 
				checkArgs = checkArgs,
				declareVariable = declareVariable,
				getValueFromVariable = getValueFromVariable,
				interpret = interpret,
				parseInput = parseInput,
				compare = compare,
				scopeHandle = scopeHandle,
				checkFile = checkFile,
				registerError = registerError,
			}) or args
			args = result
		end
	end

	-- Declaration handler
	if vdec == true then
		if tokens[2] == "=" then
			local vname = tokens[1]
			local valstart = 3

			if not tokens[3] then
				throwNew("error", 17, "")
			end
			
			local res = parseInput(valstart, tokens, false, true, args.definedScope)

			if args.definedScope then
				declareVariable(args.definedScope, vname, res)
			else
				declareVariable(0x0, vname, res)
			end
		end
	end

	-- Pass otherf stuff to next thread

	if #otherf > 0 then
		local str = table.concat(otherf, " ")

		if args.ignoreOtherf == true then
			local sendBack = {}
			for name, value in pairs(args) do
				if name ~= "definedScope" and name ~= "ignoreOtherf" then
					table.insert(sendBack, {name, value})
				end
			end
			return {str, sendBack}
		else
			local sendArgs = args
			sendArgs.ignoreOtherf = true
			local next_ = str
			while next_ ~= nil do
				next_ = interpret(next_, sendArgs)
				for _, argument in pairs(next_[2]) do
					args[argument[1]] = argument[2]
				end
				next_ = next_[1]
			end
		end
	else
		if args.ignoreOtherf ~= true then
			return args
		end
	end
end

local cmdline
local filename

cmdline = function()
	io.write("> ")
	local string = io.read("*l")
	interpret(string)
	cmdline()
end

local function displayDetails()
	print("Rocket v3.0")
	print("Find out more at rocket.alexflax.xyz")
	print("Made by alexfdev0 at github.com/alexfdev0")
	print("Licensed under GNU GPL 3.0")
	print("Copyright (c) 2025 Alexander Flax")
end

if ENV_ROBLOX == true then
	-- Roblox environment
	cmdline = function(String)
		interpret(String)
	end
	displayDetails()
	print("OS: Roblox")
	declareVariable(0x0, "STD_IS_ROBLOX", true, true, true)
	RBLX_EVENT.Event:Connect(function(String)
		cmdline(String)
	end)
else
	-- Non-roblox environment
	local filename = arg[1]
	if filename ~= nil then
		local file = io.open(filename, "r")
		if not file then
			throwNew("error", 11, filename)
		end
		local content = file:read("*a")
		file:close()

		declareVariable(0x0, "STD_FILENAME", filename, true, true)

		for i, value in ipairs(arg) do
			if arg[i + 1] then
				declareVariable(0x0, "STD_ARG" .. tostring(i), arg[i + 1], true, true)
			end
		end
		interpret(content)
	else
		displayDetails()
		local OS = os.getenv("OS")
		if OS == "Windows_NT" then
			print("OS: Windows NT (Win32)")
			declareVariable(0x0, "STD_IS_NTFS", true, true, true)
		elseif os.execute("uname -s > /dev/null") then
			local handle = io.popen("uname -s")
			local result = handle:read("*a")
			handle:close()
			print("OS: " .. result:gsub("\n", ""))
		else
			print("OS: Unknown Unix-like OS")
		end
		cmdline()
	end
end
