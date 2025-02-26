local variables = {}

local functions = {}

local validsecondclass = {
    "=",
}

local validfirstclass = {
    "print",
    "if",
    "function",
    "call",
    "calc"
}

local errors = {
    [1] = "Unknown argument(s)",
    [2] = "Unknown instruction",
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
    [16] = "Variable does not exist",
    [17] = "Value not supplied",
    [18] = "Illegal comparison"
}

function throwNew(typeo, error, args)
    etext = errors[error]
    if typeo == "warning" then
        print("Warning: " .. etext .. " " .. args .. " (Warning " .. tostring(error) .. ")")
    elseif typeo == "error" then
        print("Error: " .. etext .. " " .. args .. " (Error " .. tostring(error) .. ")")
        os.exit(error)
    end
end

function checkArgs(expct, tokens)
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
    end
end

function getValueFromVariable(variable)
    if variables[variable] then
        return variables[variable]
    else
        return nil
    end
end

function parseInput(valstart, tokens, checkfor, tokenassoc)
    --[[
    example: {"y", "=", "1", "+", "1"} (y = 1 in this istance)
    We need to parse it so it is {"y", "=", "2"}
    ]]
    local function solve(fnum, op, lnum)
        if op == "+" then
            return fnum + lnum
        elseif op == "-" then
            return fnum - lnum
        elseif op == "*" then
            return fnum * lnum
        elseif op == "/" then
            return fnum / lnum
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
    -- Check for lone variable
    if valstart == #tokens and checkfor == true then
        if getValueFromVariable(tokens[valstart]) then
            return getValueFromVariable(tokens[valstart])
            -- If not then assume it is a string being passed and move it along.
        end
    end
    -- Check for arithmetic operation
    local opsect = tokens[valstart + 1]
    if opsect == "+" or opsect == "-" or opsect == "*" or opsect == "/" or opsect == "^" then
        local fnum = tokens[valstart]
        local lnum = tokens[valstart + 2]
        -- Check for if they are numbers or variables
        if tonumber(fnum) then
            fnum = tonumber(fnum)
        else
            if tonumber(getValueFromVariable(fnum)) then
                fnum = tonumber(getValueFromVariable(fnum))
            else
                if tonumber(getValueFromVariable(fnum)) ~= nil then
                    throwNew("error", 12, "")
                else
                    throwNew("error", 16, "")
                end
            end
        end
        if tonumber(lnum) then
            lnum = tonumber(lnum)
        else
            if tonumber(getValueFromVariable(lnum)) then
                lnum = tonumber(getValueFromVariable(lnum))
            else
                if getValueFromVariable(lnum) ~= nil then
                    throwNew("error", 12, "")
                else
                    throwNew("error", 16, "")
                end
            end
        end
        return solve(fnum, opsect, lnum)
    end
    -- Check for lone numbers
    if tonumber(tokens[valstart]) then
        checkArgs(valstart, tokens)
        return tonumber(tokens[valstart])
    end
    -- Check for strings
    if valstart == #tokens then
        if string.find(tokens[valstart], '"') then
            local count = 0

            for _ in string.gmatch(tokens[valstart], '"') do
                count = count + 1
            end

            if count < 2 then
                throwNew("error", 15, "")
            end

            tokens[valstart] = tokens[valstart]:gsub('"', "")
        else
            if getValueFromVariable(tokens[valstart]) then
                tokens[valstart] = getValueFromVariable(tokens[valstart])
            else
                throwNew("error", 16, "")
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

local function compare(tokens, condstart, condend)
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
            if tokens[i] ~= "=" then
                table.insert(firsttokens, tokens[i])
            else
                equalloc = i
                break
            end
        end

        local firstres = parseInput(1, firsttokens)

        if equalloc == 0 then
            throwNew("error", 18, "")
        end

        for i = equalloc + 1, condend do
            table.insert(secondtokens, tokens[i])
        end

        local secondres = parseInput(1, secondtokens)

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
            if tokens[i] ~= "=" then
                table.insert(restokens, tokens[i])
            else
                equalloc = i
                break
            end
        end

        local first = parseInput(1, restokens)

        if equalloc == 0 then
            throwNew("error", 18, "")
        end

        for i = equalloc + 1, condend do
            table.insert(exptokens, tokens[i])
        end

        local second = parseInput(1, exptokens)

        if first == second then
            return true
        else
            return false
        end
    end
end

local interpret

interpret = function(text, args)
    if args == nil then
        args = {}
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

    if tokens[1] == "if" or tokens[1] == "function" then
        local depth = 0
        
        for i = 1, #tokens do
            if tokens[i] == "function" or tokens[i] == "if" then
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
            token = tokens[i]
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
            local res = parseInput(2, tokens, true)
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
                interpret(portion)
            end

            if compare(tokens, 2, thenloc - 1) then
                execFunc()
            end
        elseif name == "function" then
            local fname = tokens[2]
            local isend = false
            local portion = ""
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
                functions[fname] = {portion, {}}
            elseif tokens[3] == "args" then
                local args = {}
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
        elseif name == "call" then
            local fname = tokens[2]
            if functions[fname] then
                local args = functions[fname][2]
                checkArgs(2 + #args, tokens)
                for i, arg in pairs(args) do
                    local argname = arg
                    local relevantval
                    if variables[tokens[2 + i]] then
                        relevantval = variables[tokens[2 + i]]
                    else
                        relevantval = tokens[2 + i]
                    end
                    variables[argname] = relevantval
                end
                interpret(functions[fname][1], functions[fname][2])
                for i, arg in pairs(args) do
                    variables[arg] = nil
                end
            else
                throwNew("warning", 8, fname)
            end
        elseif name == "calc" then
            local fnum = tokens[2]
            local op = tokens[3]
            local lnum = tokens[4]
            fnum = tonumber(fnum)
            lnum = tonumber(lnum)
            if fnum == nil or lnum == nil then
                throwNew("error", 12, "")
            end

            if op ~= "+" and op ~= "-" and op ~= "*" and op ~= "/" then
                throwNew("error", 13, "")
            end

            local res = "n/a"

            if lnum == 0 and op == "/" then
                throwNew("warning", 14, "")
            else
                if op == "+" then
                    res = fnum + lnum
                elseif op == "-" then
                    res = fnum - lnum
                elseif op == "*" then
                    res = fnum * lnum
                elseif op == "/" then
                    res = fnum / lnum
                end
            end

            if res ~= "n/a" then
                print(res)
            end
        end
    end

    -- Decleration handler
    if vdec == true then
        if tokens[2] == "=" then
            local vname = tokens[1]
            local valstart = 3

            if not tokens[3] then
                throwNew("error", 17, "")
            end
            
            local res = parseInput(valstart, tokens)

            if res then
                variables[vname] = res
            end
        end
    end

    -- Pass otherf stuff to next thread

    if #otherf > 0 then
        local str = ""
        for i = 1, #otherf do
            if i == 1 then
                str = str .. otherf[i]
            else
                str = str .. " " .. otherf[i]
            end
        end

        interpret(str, {})
    end
end

local exec

exec = function()
    io.write("rocket > ")
    local string = io.read("*l")
    interpret(string)
    exec()
end

local filename = arg[1]
if filename ~= nil then
    local file = io.open(filename, "r")
    if not file then
        throwNew("error", 11, filename)
    end
    local content = file:read("*a")
    file:close()
    interpret(content)
else
    print("Rocket version 2")
    local os = os.getenv("OS")
    if os then
        print("OS: " .. os)
    end
    exec()
end