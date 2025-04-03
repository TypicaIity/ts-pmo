--!strict
--!optimize 2

local parser = {}

local lexer = require("lexer")
local common = require("common")

export type Node = {
	t: string, -- node type
	body: Tree?,
	data: { [string]: any } -- data unique to each node type
}
export type Tree = { Node }

local ERR_UNEXPECTEDTOKEN = "unexpected token '%s' at line %d, column %d"
local ERR_UNEXPECTEDTOKENV = "unexpected token '%s' at line %d, column %d (expected '%s')"

local instructions = common.instructions

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
	
		for _, tt in ipairs(types) do
			if tv == nil then
				if t.t == tt then
					return true
				end
			else
				if t.t == tt and t.v == tv then
					return true
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

			local insn = instructions[token.v]
			
			local operands: { lexer.Token } = { }
			local count: number | { number } = insn.operands

			if type(count) == "table" then
				local operandCount = 0
				
				while not match("NEWLINE|EOF") do
					operandCount += 1
					i += 1
				end
				assert(table.find(count, operandCount), "operand count mismatch")
				i -= operandCount -- go back
				for j=1, operandCount do
					local t = expect(insn.types)
					if t.t == "IDENTF" then t.t = "REG" end
					table.insert(operands, t)
					if j ~= operandCount then expect("PUNCT", ",") end
				end
			else
				assert(type(count) == "number")
				for j=1,count do
					local t = expect(insn.types)
					if t.t == "IDENTF" then t.t = "REG" end
					table.insert(operands, t)
					if j ~= count then expect("PUNCT", ",") end -- expect a comma if its not the last operand
				end
			end
			
			if i < #tokens then expect("NEWLINE")
			else expect("EOF") end
			
			local node: Node = { t = "INSN", data = { mnemonic = token.v, operands = operands } }
			table.insert(tree, node)			
			
		elseif token.t == "NEWLINE" then
			i += 1

		else
			error(ERR_UNEXPECTEDTOKEN:format(token.v, token.l, token.cb))
		end
	end

	return ast
end

return parser
