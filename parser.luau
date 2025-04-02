--!strict
--!optimize 2

local parser = {}

local lexer = require("lexer")

export type Node = {
	t: string, -- node type
	body: Tree?,
	data: { [string]: any } -- data unique to each node type
}
export type Tree = { Node }

local ERR_UNEXPECTEDTOKEN = "unexpected token '%s' at line %d, column %d"
local ERR_UNEXPECTEDTOKENV = "unexpected token '%s' at line %d, column %d (expected '%s')"

local keywords = {
	["mov"] = {operands = 2, types = "IMM|REG|MEM}
	["call"] = 1, 
	["jmp"] = 1, 
	["cmp"] = 2, 
	["add"] = 2, 
	["sub"] = 2, 
	["mul"] = 1, 
	["div"] = 1,
	["inc"] = 1, 
	["dec"] = 1, 
	["and"] = 2, 
	["or"] = 2, 
	["xor"] = 2, 
	["not"] = 1, 
	["shl"] = 2, 
	["shr"] = 2,
	["nop"] = 0, 
	["ret"] = 0, 
	["push"] = 1, 
	["pop"] = 1, 
	["test"] = 2, 
	["lea"] = 2, 
	["imul"] = 1, 
	["idiv"] = 1,
	["fld"] = 1, 
	["fst"] = 1, 
	["fstp"] = 2, 
	["fadd"] = 2, 
	["fsub"] = 2, 
	["fmul"] = 2, 
	["fdiv"] = 1, 
	["fcom"] = 1,
	["fcomp"] = 1, 
	["fxch"] = 1, 
	["fchs"] = 1, 
	["fabs"] = 0, 
	["fsin"] = 1, 
	["fcos"] = 1, 
	["fptan"]= 1,
	["f2xm1"] = 1,
	["cli"] = 1,
	["hlt"] = 1, 
	["int"] = 1,
}
parser.keywords = keywords

local registers: { string } = {
    "rax", "rbx", "rcx", "rdx", "rsp", "rip", "rbp", "rsi", "rdi",
	"r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",

    "eax", "ebx", "ecx", "edx", "esp", "eip", "ebp", "esi", "edi",

    "flags"
}
parser.registers = registers

function parser.parse(tokens: { lexer.Token }): Tree
	local ast: Tree = {}
	local i: number = 1
	local tree: Tree = {} -- the current tree to put nodes into

	-- helper functions
	local function match(tt: string, tv: string?): boolean
	    local t = tokens[i]
	    assert(t)
	    
	    -- split 'tt' by '|' if multiple types are provided
	    local types = {}
	    for type in tt:gmatch("[^|]+") do
	        table.insert(types, type)
	    end
	
	    for _, type in ipairs(types) do
	        if type == "REG" then
	            if t.t == "IDENTF" and table.find(registers, t.v) ~= nil then
	                return true
	            end
	        else
	            if tv == nil then
	                if t.t == type then
	                    return true
	                end
	            else
	                if t.t == type and t.v == tv then
	                    return true
	                end
	            end
	        end
	    end
	
	    return false
	end

	local function expect(tt: string, tv: string?): lexer.Token
		local t = tokens[i] -- get the current token
		assert(t)
		if tv ~= nil then
			assert(match(tt, tv), ERR_UNEXPECTEDTOKENV:format(t.v, t.l, t.cb, tv))
		else
			assert(match(tt, tv), ERR_UNEXPECTEDTOKEN:format(t.v:gsub("\n", "\\n"), t.l, t.cb))
		end
		i += 1
		return t
	end

	while i < #tokens do
		local token = tokens[i]

		if match("IDENTF", "section") then
			i += 2 -- skip 'section' and '.'
			local name: string = expect("IDENTF").v
			expect("PUNCT", ":")
			local node: Node = { t = "SECTION", data = { name = "." .. name }, body = {} }
			table.insert(ast, node)
			tree = node.body :: Tree

		elseif token.t == "IDENTF" and table.find(keywords, token.v) then
			i += 1 -- skip the keyword
			-- to expect a register, use: expect("REG")
			if token.v == "ret" and tokens[i].t == "IMM" then
				expect("IMM")
			else
				for j = 1, keywords[token.v] do
					expect("IDENTIF",	) --i didn't finish noob
			end 
			if i < #tokens then expect("NEWLINE") else expect("EOF") end
			
		elseif token.t == "NEWLINE" then
			i += 1

		else
			error(ERR_UNEXPECTEDTOKEN:format(token.v, token.l, token.cb))
		end
	end

	return ast
end

return parser
