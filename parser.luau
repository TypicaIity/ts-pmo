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

local keywords: { string } = {
	"mov", "call", "jmp", "cmp", "add", "sub", "mul", "div",
	"inc", "dec", "and", "or", "xor", "not", "shl", "shr",
	"nop", "ret", "push", "pop", "test", "lea", "imul", "idiv",
	"fld", "fst", "fstp", "fadd", "fsub", "fmul", "fdiv", "fcom",
	"fcomp", "fxch", "fchs", "fabs", "fsin", "fcos", "fptan", "f2xm1",
	"cli", "hlt", "int"
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
	local tree: Tree = ast -- the current tree to put nodes into

	-- helper functions
	local function match(tt: string, tv: string?): boolean
		local t = tokens[i]
		assert(t)
		if tt == "REG" then
			return t.t == "IDENTF" and table.find(registers, t.v) ~= nil
		else
			if tv == nil then
				return t.t == tt
			end
			return t.t == tt and t.v == tv
		end
	end

	local function expect(tt: string, tv: string?): lexer.Token
		local t = tokens[i] -- get the current token
		assert(t)
		if tv ~= nil then
			assert(match(tt, tv), ERR_UNEXPECTEDTOKENV:format(t.v, t.l, t.cb, tv))
		else
			assert(match(tt, tv), ERR_UNEXPECTEDTOKEN:format(t.v:gsub("\n", "\\n"):gsub("\t", "\\t"), t.l, t.cb))
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
			local node: Node = { t = "SECTION", data = { name = name }, body = {} }
			table.insert(tree, node)
			tree = node.body :: Tree

		elseif token.t == "IDENTF" and table.find(keywords, token.v) then
			i += 1 -- skip the keyword
			-- to expect a register, use: expect("REG")
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
