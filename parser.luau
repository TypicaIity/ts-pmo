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

local instructions = {
    ["mov"] = {operands = 2, types = "IMM|REG|MEM"},
    ["call"] = {operands = 1, types = "IMM|REG|MEM"},
    ["jmp"] = {operands = 1, types = "IMM|REG|MEM"},
    ["cmp"] = {operands = 2, types = "IMM|REG|MEM"},
    ["add"] = {operands = 2, types = "IMM|REG|MEM"},
    ["sub"] = {operands = 2, types = "IMM|REG|MEM"},
    ["mul"] = {operands = 2, types = "IMM|REG|MEM"},
    ["div"] = {operands = 2, types = "IMM|REG|MEM"},
    ["inc"] = {operands = 1, types = "REG|MEM"},
    ["dec"] = {operands = 1, types = "REG|MEM"},
    ["and"] = {operands = 2, types = "IMM|REG|MEM"},
    ["or"] = {operands = 2, types = "IMM|REG|MEM"},
    ["xor"] = {operands = 2, types = "IMM|REG|MEM"},
    ["not"] = {operands = 1, types = "REG|MEM"},
    ["shl"] = {operands = 2, types = "IMM|REG|MEM"},
    ["shr"] = {operands = 2, types = "IMM|REG|MEM"},
    ["nop"] = {operands = 0, types = ""},
    ["ret"] = {operands = {0, 1}, types = "IMM"},
    ["push"] = {operands = 1, types = "REG|MEM"},
    ["pop"] = {operands = 1, types = "REG|MEM"},
    ["test"] = {operands = 2, types = "IMM|REG|MEM"},
    ["lea"] = {operands = 2, types = "REG|MEM"},
    ["imul"] = {operands = 2, types = "IMM|REG|MEM"},
    ["idiv"] = {operands = 2, types = "IMM|REG|MEM"},
    ["fld"] = {operands = 1, types = "MEM"},
    ["fst"] = {operands = 1, types = "MEM"},
    ["fstp"] = {operands = 1, types = "MEM"},
    ["fadd"] = {operands = 1, types = "MEM"},
    ["fsub"] = {operands = 1, types = "MEM"},
    ["fmul"] = {operands = 1, types = "MEM"},
    ["fdiv"] = {operands = 1, types = "MEM"},
    ["fcom"] = {operands = 1, types = "MEM"},
    ["fcomp"] = {operands = 1, types = "MEM"},
    ["fxch"] = {operands = 1, types = "REG"},
    ["fchs"] = {operands = 0, types = ""},
    ["fabs"] = {operands = 0, types = ""},
    ["fsin"] = {operands = 0, types = ""},
    ["fcos"] = {operands = 0, types = ""},
    ["fptan"] = {operands = 0, types = ""},
    ["f2xm1"] = {operands = 0, types = ""},
    ["cli"] = {operands = 0, types = ""},
    ["hlt"] = {operands = 0, types = ""},
    ["int"] = {operands = 1, types = "IMM"}
}
parser.instructions = instructions

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

		elseif token.t == "IDENTF" and instructions[token.v] then
			i += 1 -- skip the keyword
			-- to expect a register, use: expect("REG")
			local operands = {}
			if token.v == "ret" and tokens[i].t == "IMM" then
				expect("IMM")
			else
				for _ = 1, instructions[token.v].operands do
					table.insert(operands, tokens[i].v)
					expect(instructions[token.v].types)
				end
			end 
			local node: Node = { t = "INSTR", data = { mnemonic = token.v, operands = operands } }
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
