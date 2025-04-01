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

	src ..= "\0" -- add eof

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
			
			local c: string = src:sub(j, j)
			while c:match("[a-zA-Z_0-9]") do
				buf ..= c
				j += 1
				c = src:sub(j, j)
			end
			i = j -- move the 
			table.insert(tokens, { t = "IDENTF", v = buf, l = lineNumber, cb = i, ce = j })
		
		elseif ch:match("[,%.:]") then
			-- collect punctuation
			table.insert(tokens, { t = "PUNCT", v = ch, l = lineNumber, cb = i, ce = i + 1 })
			i += 1

		elseif ch == ";" then
			-- skip comments
			local j: number = i
			while src:sub(j, j) ~= "\n" do
				j += 1
			end
			i = j

		elseif ch == "\n" then
			table.insert(tokens, { t = "NEWLINE", v = ch :: string, l = lineNumber, cb = i, ce = i + 1 })
			lineNumber += 1
			i += 1

		-- ignore whitespace
		elseif ch:match("%s") then
			i += 1

		else
			error(`unexpected character '{ch}'`)
		end
	end

	return tokens
end

return lexer
