--!strict
--!optimize 2

local lexer = require("lexer")
local parser = require("parser")

print(parser.parse(lexer.tokenize([[
section .text:
	;
]])))
