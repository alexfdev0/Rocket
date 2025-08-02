local package_ = {}

package_.bundle = {
    {
        name = "print",
        func = function (lang)
            local message = lang.parseInput(2, lang.tokens, true, false, lang.args.definedScope)

            print(message)

            return lang.args
        end
    },
    {
        name = "io_read",
        func = function (lang)
            local mode = lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope)

            if mode ~= "*a" and mode ~= "*l" and mode ~= "*n" then
                lang.throwNew("error", lang.registerError("Invalid mode"), mode)
            end

            lang.args.returnValue = io.read(mode)

            return lang.args
        end
    },
    {
        name = "io_write",
        func = function (lang)
            local message = lang.parseInput(2, lang.tokens, true, false, lang.args.definedScope)

            io.write(message)

            return lang.args
        end
    }, 
    {
        name = "io_open",
        func = function (lang)
            local filename = lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope)
            local mode = lang.parseInput(1, { lang.tokens[3] }, true, false, lang.args.definedScope)

            if mode ~= "r" and mode ~= "w" and mode ~= "a" and mode ~= "r+" and mode ~= "w+" and mode ~= "a+" then
                lang.throwNew("error", lang.registerError("Invalid mode"), mode)
            end

            local file = io.open(filename, mode)

            if file then
               lang.args.returnValue = file 
            else
                lang.throwNew("error", lang.registerError("Could not open file"), filename)
            end

            return lang.args
        end
    },
    {
        name = "io_close",
        func = function (lang)
            local file = lang.getValueFromVariable(lang.tokens[2])

            if type(file) == "userdata" then
                io.close(file)
                lang.declareVariable(lang.args.definedScope, lang.tokens[2], nil, false, false)
            else
                lang.throwNew("error", lang.registerError("Not a valid file"), lang.tokens[2])
            end

            return lang.args
        end
    },
    {
        name = "file_write",
        func = function (lang)
            local file = lang.getValueFromVariable(lang.tokens[2])
            local contents = lang.parseInput(3, lang.tokens, true, false, lang.args.definedScope)

            if type(file) == "userdata" then
                file:write(contents)
            else
                lang.throwNew("error", lang.registerError("Not a valid file"), lang.tokens[2])
            end

            return lang.args
        end
    },
    {
        name = "exit",
        func = function (lang)
            local code = tonumber(lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope))

            if code == nil then
                lang.throwNew("error", lang.registerError("Invalid number"), "")
            end

            os.exit(code)
        end
    }
}

return package_