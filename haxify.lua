-- Be warned, here be dragons

api = require "love-api.love_api"

do
	-- Map types to their modules, so we can properly do imports
	local lovetypes = {}

	for _, type in ipairs(api.types) do
		lovetypes[type.name] = "love"
	end

	for _, module in ipairs(api.modules) do
		local modulename = "love." .. module.name
		if module.types then
			for _, type in ipairs(module.types) do
				lovetypes[type.name] = modulename
			end
		end
		if module.enums then
			for _, type in ipairs(module.enums) do
				lovetypes[type.name] = modulename
			end
		end
	end

	-- types: { name -> true }
	function resolveImports(types, package)
		local imports = {}
		for i, v in pairs(types) do
			local module = lovetypes[i]
			if module and module ~= package then
				table.insert(imports, ("import %s.%s;"):format(module, i))
			end
		end
		table.sort(imports)
		return table.concat(imports, "\n")
	end
end

do
	-- The keys are type names, the values are their "priority",
	-- the most generic base class (Object) has the lowest priority.
	-- Used to find the most specific supertype later on.
	local priority = {}
	priority["Object"] = 0

	-- Now we first need a complete registry of types and their supertypes
	local supertypes = {}
	for _, type in ipairs(api.types) do
		supertypes[type.name] = type.supertypes or {}
	end

	for _, module in ipairs(api.modules) do
		if module.types then
			for _, type in ipairs(module.types) do
				supertypes[type.name] = type.supertypes or {}
			end
		end
		if module.enums then
			for _, type in ipairs(module.enums) do
				supertypes[type.name] = type.supertypes or {}
			end
		end
	end

	-- To assign the priority of a type, take the maximum priority of its
	-- supertypes and add 1.
	local function assignPriority(name)
		if priority[name] then
			-- Priority is known, skip
			return priority[name]
		end

		local max = -math.huge
		for i, v in ipairs(supertypes[name]) do
			max = math.max(max, assignPriority(v))
		end

		priority[name] = max+1
		return max+1
	end

	-- Now assign all priorities, and dump the type list
	for i, v in pairs(supertypes) do
		assignPriority(i)
	end
	supertypes = nil

	-- Now we can just return the supertype with the highest priority
	function mostSpecificSupertype(t)
		local maxVal, maxPriority = "UserData", -math.huge
		for i, v in ipairs(t) do
			local priority = priority[v]
			if priority > maxPriority then
				maxVal, maxPriority = v, priority
			end
		end
		return maxVal
	end
end

do
	local map =
	{
		number = "Float",
		string = "String",
		boolean = "Bool",
		table = "Table<Dynamic,Dynamic>",
		["light userdata"] = "UserData",
		userdata = "UserData",
		["function"] = "Dynamic", -- FIXME
		mixed = "Dynamic",
		value = "Dynamic",
		any = "Dynamic",
		Variant = "Dynamic",

		-- FIXME
		cdata = "CompressedData",
		["ShaderVariableType"] = "String",
		["KeyConstant"] = "String",
		["Scancode"] = "String",
	}
	
	function typeMap(t)
		local thgn = ""
		if map[t] then
			thgn =  map[t]
		else
			thgn = t
		end
		--thgn = thgn:gsub("or string", "")
		if thgn:find(" or ") then
			thgn = "Dynamic"
		end
		if thgn == nil or thgn == "nil" then
			thgn = "Dynamic"
		end
		return thgn
	end
end

function capitalize(s)
	return s:sub(1, 1):upper() .. s:sub(2)
end

function mergeTables(target, src, prefix)
	prefix = prefix or ""
	for i, v in pairs(src) do
		target[prefix .. i] = v
	end
	return target
end

function dirname(path)
	return path:match("^(.-)/?[^/]+$")
end

function emitMultiReturnType(name, returns, types)
	local parts = {}
	parts[1] = ("\n@:multiReturn\nextern class %s\n{\n"):format(name)
	local timesThingsHaveBeenIn = {}
	for i, v in ipairs(returns) do
		if v.name ~= "..." then
			--local type = typeMap(v.type)
			if not timesThingsHaveBeenIn[v.name] then
				timesThingsHaveBeenIn[v.name] = 1
			else
				local thaaang = timesThingsHaveBeenIn[v.name]
				v.name = v.name .. tostring(thaaang)
				timesThingsHaveBeenIn[v.name] = thaaang + 1
			end
		end
	end
	for i, v in ipairs(returns) do
		-- TODO: Maybe never? Vararg return can't really be modeled.
		if v.name ~= "..." then
			local type = typeMap(v.type)
			types[type] = true
			local thingsGoneThrough = {}
			local bleh = ""
			--if thingsGoneThrough[type] then
			--	bleh = thingsGoneThrough[type]
			--	thingsGoneThrough[type] = thingsGoneThrough[type] + 1
			--end
			--table.insert(parts, ("\tvar %s : %s;\n"):format(v.name, type))
			--genuinly no idea whats causing it. fuck off.
			table.insert(parts, "\tvar " .. v.name .. bleh .. " : " .. type .. ";\n")
			--if not thingsGoneThrough[type] then
			--	thingsGoneThrough[type] = 1
			--end
		end
	end
	table.insert(parts, "}")

	return table.concat(parts)
end

function emitOverload(typeName, name, o, types, multirets)
	local args = {}
	for i, v in ipairs(o.arguments or {}) do
		v.type = typeMap(v.type)
		types[v.type] = true

		v.name = v.name:match("^\"(.*)\"$") or v.name -- FIXME: workaround for love.event.quit

		if v.name == "..." then
			table.insert(args, ("args:Rest<%s>"):format(v.type))
		else
			local arg = (v.default and "?" or "") .. v.name .. ":" .. v.type
			table.insert(args, arg)
		end
	end
	local retType = "Void"
	if o.returns and #o.returns > 1 then
		-- In case of multiple returns we need to generate a new return type
		retType = typeName .. capitalize(name) .. "Result"
		multirets[name] = emitMultiReturnType(retType, o.returns, types)
	elseif o.returns then
		retType = typeMap(o.returns[1].type)
		types[retType] = true
	end
	return ("(%s) : %s"):format(table.concat(args, ", "), retType)
end

function emitCallback(c, types)
	local type = {}
	for i, v in ipairs(c.variants[1].arguments or {}) do -- TODO: Multiple variants? Does that even exist?
		table.insert(type, typeMap(v.type))
		types[type[#type]] = true
	end

	if c.variants[1].returns then -- TODO: Multiple returns?
		table.insert(type, typeMap(c.variants[1].returns[1].type))
		types[type[#type]] = true
	else
		table.insert(type, "Void")
	end

	-- If there are no arguments, prepend Void
	if #type == 1 then
		table.insert(type, 1, "Void")
	end

	type = table.concat(type, "->")

	return ("\tpublic static var %s : %s;"):format(c.name, type)
end

function rawEmitFunction(typeName, f, types, static, multirets)
	local out = {""}

	local sigs = {}
	for i, v in ipairs(f.variants) do
		table.insert(sigs, emitOverload(typeName, f.name, v, types, multirets))
	end

	local main = table.remove(sigs, 1)
	for i, v in ipairs(sigs) do
		table.insert(out, ("\t@:overload(function %s {})"):format(v))
	end
	table.insert(out, ("\tpublic%s function %s%s;"):format(static and " static" or "", f.name, main))
	return table.concat(out, "\n")
end

function emitFunction(typeName, f, types, multirets)
	return rawEmitFunction(typeName, f, types, true, multirets)
end

function emitMethod(typeName, m, types, multirets)
	return rawEmitFunction(typeName, m, types, false, multirets)
end

function tableHasValue(_table, value)
	for i=1, #_table do
		local tblVal = _table[i]
		if tblVal == value then
			return true
		end
	end
	return false
end

function emitEnum(e, packageName)
	local out = {}
	table.insert(out, ("package %s;"):format(packageName))
	table.insert(out, "enum")
	table.insert(out, ("abstract %s (String)\n{"):format(e.name))

	for i, v in ipairs(e.constants) do
		local nname = v.name
		local nnamefirst = string.sub(nname, 1, 1)
		local invalidNames = {
			["%!"] = "exclamationmark",
			["%\""] = "doublequote",
			["%#"] = "hash",
			["%$"] = "dollar",
			["%&"] = "ampersand",
			["%'"] = "singlequote",
			["%("] = "leftparenthesis",
			["%)"] = "rightparenthesis",
			["%*"] = "asterisk",
			["%+"] = "plus",
			["%,"] = "comma",
			["%-"] = "hyphen",
			["%."] = "period",
			["%/"] = "slash",
			["%:"] = "colon",
			["%;"] = "semicolon",
			["%<"] = "lessthan",
			["%="] = "equals",
			["%>"] = "greaterthan",
			["%?"] = "questionmark",
			["%@"] = "at",
			["%["] = "leftbracket",
			["%\\"] = "backslash",
			["%]"] = "rightbracket",
			["%^"] = "caret",
			["%_"] = "underscore",
			["%`"] = "backtick"
		}
		
		if tonumber(nnamefirst) ~= nil then
			nname = "_" .. nname 
		end
		--nnamefirst = "%" .. nnamefirst
		if invalidNames["%" .. nnamefirst] then
			nname = nname:gsub('%' .. nnamefirst, invalidNames['%' .. nnamefirst])
		end
		if v.name == "\"" then
			v.name = "\\\""
		end
		if v.name == "\\" then
			v.name = "\\\\"
		end
		if #nname > 1 then
			local nnamelast = string.sub(nname, #nname, #nname)
			if invalidNames["%" .. nnamelast] then
				nname = nname:gsub('%' .. nnamelast, "_" .. invalidNames['%' .. nnamelast])
			end
		end
		table.insert(out, ("\tvar %s = \"%s\";"):format(capitalize(nname), v.name))
	end

	table.insert(out, "}")
	return {[e.name .. ".hx"] = table.concat(out, "\n")}
end

function emitHeader(out, packageName)
	table.insert(out, ("package %s;"):format(packageName))
	table.insert(out, "import haxe.extern.Rest;")
	table.insert(out, "import lua.Table;")
	table.insert(out, "import lua.UserData;")
	table.insert(out, "")
end

function emitType(t, packageName)
	local out = {}
	local types = {}
	local multirets = {}
	emitHeader(out, packageName)

	local superType = t.supertypes and mostSpecificSupertype(t.supertypes) or "UserData"
	table.insert(out, ("extern class %s extends %s\n{"):format(t.name, superType))

	for i, v in ipairs(t.functions or {}) do
		table.insert(out, emitMethod(t.name, v, types, multirets))
	end

	table.insert(out, "}")
	table.insert(out, 2, resolveImports(types, packageName))

	for i, v in pairs(multirets) do
		table.insert(out, v)
	end
	return {[t.name .. ".hx"] = table.concat(out, "\n")}
end

function emitModule(m, luaName)
	local out = {}
	local files = {}
	local types = {}
	local multirets = {}

	local moduleName = luaName or "love." .. m.name
	local prefix = moduleName:gsub("%.", "/") .. "/"
	emitHeader(out, moduleName)
	table.insert(out, ("@:native(\"%s\")"):format(moduleName))
	local className = capitalize(luaName or (m.name .. "Module"))
	table.insert(out, ("extern class %s"):format(className))
	table.insert(out, "{")

	for i, v in ipairs(m.functions) do
		table.insert(out, emitFunction(className, v, types, multirets))
	end

	for i, v in ipairs(m.callbacks or {}) do
		table.insert(out, emitCallback(v, types))
	end

	table.insert(out, "}")

	for i, v in ipairs(m.enums or {}) do
		mergeTables(files, emitEnum(v, moduleName), prefix)
	end

	for i, v in ipairs(m.types or {}) do
		mergeTables(files, emitType(v, moduleName), prefix)
	end

	table.insert(out, 2, resolveImports(types, moduleName))

	for i, v in pairs(multirets) do
		table.insert(out, v)
	end
	files[prefix .. className .. ".hx"] = table.concat(out, "\n")
	return files
end

local files = {}

for i, v in ipairs(api.modules) do
	mergeTables(files, emitModule(v))
end

mergeTables(files, emitModule(api, "love"))

local realylDOFullThing = true

local outPath = "EXTERNS/src"
local outFirstFolder = "EXTERNS"

os.execute("mkdir " .. outPath)

if realylDOFullThing then

	for i, v in pairs(files) do
        local drnam = outPath .. "/" .. dirname(i)
        print(drnam)
        if drnam ~= outPath .. "/" then
			os.execute("mkdir " .. drnam:gsub("/", "\\"))
			--print("\"\" > " .. outPath:gsub("/", "\\") .. "\\" .. i:gsub("/", "\\"))
            local f = io.open(outPath:gsub("/", "\\") .. "\\" .. i:gsub("/", "\\"), "w")
            if f then
                f:write(v)
                f:close()
            else
                print("Failed to open file: " .. outPath:gsub("/", "\\") .. "\\" .. i:gsub("/", "\\"))
            end
        end
    end
end

--https://stackoverflow.com/questions/5303174/how-to-get-list-of-directories-in-lua
--modified with chatgpt bc lazy shut up
function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile
    if package.config:sub(1, 1) == '\\' then
        -- Windows
        pfile = popen('dir "'..directory..'" /b /a')
    else
        -- Unix-like systems (Linux, macOS)
        pfile = popen('ls -a "'..directory..'"')
    end
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end


--local haxelibStuffsDir = scandir("./haxelibstuffs")

local function copyDirectory(dir)

end

function is_dir(path)
    local f = io.open(path:gsub("/", "\\"), "r")
	if not f then return true end
    return not f:read(0) and f:seek("end") ~= 0
end

copyDirectory = function(dir)
	local direct = scandir("./" .. dir)
	for i = 1, #direct do 
		local file = direct[i]
		print("THINGTHING")
		print(dir .. "\\" .. file)
		if is_dir(dir .. "\\" .. file) then
			print(outFirstFolder .. "\\" .. file)
			print("UUUGH")
			print(outFirstFolder .. "\\" .. dir)
			os.execute("mkdir " .. outFirstFolder .. "\\" .. dir:gsub("haxelibstuffs", "") .. "\\" .. file)
			print(dir .. "\\" .. file)
			copyDirectory(dir .. "\\" .. file)
		else
			print(dir:gsub("haxelibstuffs", "") .."\\" .. file)
			os.execute("copy " .. dir .. "\\" .. file .. " " .. outFirstFolder .. "\\" .. dir:gsub("haxelibstuffs", "") .."\\" .. file)
		end
		--print(direct[i]) 
	end
end

copyDirectory("haxelibstuffs")

--[[for i = 1, #haxelibStuffsDir do 
	local file = haxelibStuffsDir[i] 
	os.execute("copy haxelibstuffs\\" .. file .. " " .. outFirstFolder .. "\\" .. file) 
	print(haxelibStuffsDir[i]) 
end]]
