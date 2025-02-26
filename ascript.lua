local variables = {

}

local functions = {

}

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
    [14] = "Division by zero is not allowed"
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

local readText

readText = function(text, args)
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
        for j = 1, #tokens do
            if tokens[j] == "end;" then
                tokens[j] = tokens[j]:gsub(";", "")
                splitloc = j
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
            if variables[tokens[2]] then
                print(variables[tokens[2]])
            else
                local str = ""
                for i = 2, #tokens do
                    if i == 2 then
                        str = str .. tokens[i]
                    else
                        str = str .. " " .. tokens[i]
                    end
                end
                print(str)
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

            -- Address = statements
            if condstart == "=" then
                throwNew("error", 5, "")
            end

            if tokens[2 + 1] == "=" then
                local thing1 = nil
                local thing2 = nil
                if variables[condstart] then
                    thing1 = variables[condstart]
                else
                    thing1 = condstart
                end

                if tokens[2 + 2] == "then" then
                    throwNew("error", 6, "")
                end

                if variables[tokens[2 + 2]] then
                    thing2 = variables[tokens[2 + 2]]
                else
                    thing2 = tokens[2 + 2]
                end


                if thing1 == thing2 then
                    local portion = ""
                    for i = thenloc + 1, endloc - 1 do
                        if i == thenloc + 1 then
                            portion = portion .. tokens[i]
                        else
                            portion = portion .. " " .. tokens[i]
                        end
                    end
                    readText(portion)
                end
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
                readText(functions[fname][1], functions[fname][2])
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
            checkArgs(3, tokens)
            variables[tokens[1]] = tokens[3]
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

        readText(str, {})
    end
end

local exec

exec = function()
    io.write("ascript > ")
    local string = io.read("*l")
    readText(string)
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
    readText(content)
else
    print("AScript version 1.01")
    local os = os.getenv("OS")
    if os then
        print("OS: " .. os)
    end
    exec()
end