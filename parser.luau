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

function parser.parse(tokens: { lexer.Token }): Tree
	local ast: Tree = {}
	local i: number = 1
	local tree: Tree = ast -- the current tree to put nodes into

	-- helper functions
	local function match(tt: string, tv: string?): boolean
		local nt = tokens[i]
		return nt.t == tt or (tv ~= nil and nt.v == tv)
	end

	local function expect(tt: string, tv: string?): lexer.Token
		local nt = tokens[i] -- get the next token
		if tv ~= nil then
			assert(match(tt, tv), ERR_UNEXPECTEDTOKENV:format(nt.v, nt.l, nt.cb, tv))
		else
			assert(match(tt, tv), ERR_UNEXPECTEDTOKEN:format(nt.v, nt.l, nt.cb))
		end
		i += 1
		return nt
	end

	while i < #tokens do
		local token = tokens[i]

		if match("IDENTF", "section") then
			expect("IDENTF", "section")
			expect("PUNCT", ".")
			local name: string = expect("IDENTF").v
			expect("PUNCT", ":")
			local node: Node = { t = "SECTION", data = { name = name }, body = {} }
			table.insert(tree, node)
			tree = node.body :: Tree
			
		elseif token.t == "NEWLINE" then
			i += 1

		else
			-- If it's not a section, raise an error for unexpected token
			error(ERR_UNEXPECTEDTOKEN:format(token.v, token.l, token.cb))
		end
	end

	return ast
end

return parser
