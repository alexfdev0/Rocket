local package_ = {}

package_.bundle = {
    {
        name = "scope_create",
        func = function (lang)
            local addr = lang.parseInput(2, lang.tokens, true, false, lang.args.definedScope)
			lang.scopeHandle("create", addr, 0x0, true)
        end
    },
    {
        name = "scope_destroy",
        func = function (lang)
            local addr = lang.parseInput(2, lang.tokens, true, false, lang.args.definedScope)
			lang.scopeHandle("destroy", addr, nil)
        end
    },
    {
        name = "scope_add",
        func = function (lang)
            local addr = lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope)
			local vname = lang.tokens[3]
			lang.declareVariable(addr, vname, lang.parseInput(4, lang.tokens, true, false, lang.args.definedScope))

            return lang.args
        end
    },
    {
        name = "scope_remove",
        func = function (lang)
            local addr = lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope)
			local vname = lang.tokens[3]
			lang.declareVariable(addr, vname, nil)

            return lang.args
        end
    },
    {
        name = "scope_get",
        func = function (lang)
            local addr = lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope)
			local vname = lang.tokens[3]
			local value = lang.getValueFromVariable(vname, addr)
			lang.args.returnValue = value

            return lang.args
        end
    },
    {
        name = "scope_transfer",
        func = function (lang)
            local addrfrom = lang.parseInput(1, { lang.tokens[2] }, true, false, lang.args.definedScope)
			local addrto = lang.parseInput(1, { lang.tokens[3] }, true, false, lang.args.definedScope)
			local vname = lang.tokens[4]
			local vvalue
			if lang.variables[addrfrom] then
				if lang.variables[addrto] then
					for _, variable in pairs(lang.variables[addrfrom]) do
						if type(variable) == "table" then
							local name = variable[1]
							local value = variable[2]
							if name == vname then
								vvalue = value
							end
						end
					end
				else
					lang.throwNew("warning", 29, "")
				end
			else
				lang.throwNew("warning", 29, "")
			end
			lang.declareVariable(addrto, vname, vvalue)

            return lang.args
        end
    },
    {
        name = "scope_list",
        func = function (lang)
            for _, scope in pairs(lang.scopes) do
				print("0x" .. string.lower(string.format("%X", scope)))
		    end

            return lang.args
        end
    }
}

return package_