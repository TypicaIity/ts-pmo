--!strict
--!optimize 2

local lexer = {}

export type Token = {
	t: string,  -- token type
	v: string,  -- token value
	l: number,  -- line number
	cb: number, -- column where the token begins
	ce: number  -- column where the token ends
}

function lexer.tokenize(src: string): { Token }
	local tokens: { Token } = {}

	local lineNumber: number = 1
	local i: number = 1
	local col: number = 1

	while i < #src do
		local ch: string = src:sub(i, i)
		
		-- a-z/A-Z = any alphabetic character
		-- _ = underscore
		-- 0-9 = any number
		-- [...] = any character that matches ...
		-- * = any amount of the previous character
		if ch:match("[a-zA-Z_]") then
			-- collect identifiers(words)
			local buf: string = ch
			local j: number = i + 1
			local begin: number = col
			
			local c: string = src:sub(j, j)
			while c:match("[a-zA-Z_0-9]") do
				buf ..= c
				j += 1
				c = src:sub(j, j)
				col += 1
			end
			i = j -- move the 
			table.insert(tokens, { t = "IDENTF", v = buf, l = lineNumber, cb = begin, ce = col })
		
		elseif ch:match("[,%.:]") then
			-- collect punctuation
			table.insert(tokens, { t = "PUNCT", v = ch, l = lineNumber, cb = col, ce = col + 1 })
			i += 1
			col += 1

		elseif ch:match("%d") then
			local j: number = i
			local begin: number = col
			local value: string
			while src:sub(j,j):match("%d") do
				j+=1
				col+=1
			end
			if j+1 == "h" then
				value = "0x"..src:sub(i,j)
				i = j+1
				col+=1
			else
				value = src:sub(i,j)
				i = j
			end
			table.insert(tokens, { t = "IMM", v = value, l=lineNumber, cb = begin, ce = col}) 
			
		elseif ch == "[" then
			-- collect a mem token
			local j: number = i
			local begin: number = col
			while src:sub(j, j) ~= "]" do
				j += 1
				col += 1
			end
			local content: string = src:sub(i+1, j-1)
			local first, second = content:match("([+-*/])(.?)")
			assert(not second or second == "", `too many operands. line {lineNumber}, column {col}`)
			table.insert(tokens, { t = "MEM", v = content, l = lineNumber, cb = begin, ce = col + 1 })
			i = j + 1 -- skip "["
		
		elseif ch == ";" then
			-- skip comments
			local j: number = i
			while src:sub(j, j) ~= "\n" do
				j += 1
				col += 1
			end
			i = j

		elseif ch == "\n" then
			table.insert(tokens, { t = "NEWLINE", v = ch :: string, l = lineNumber, cb = col, ce = col + 1 })
			lineNumber += 1
			col = 1
			i += 1

		-- ignore whitespace
		elseif ch:match("%s") then
			i += 1
			if ch == "\t" then col += 4
			else col += 1 end

		else
			error(`unexpected character '{ch}'`)
		end
	end

	table.insert(tokens, { t = "EOF", v = "\0", l = lineNumber, cb = col, ce = col + 1 })

	return tokens
end
