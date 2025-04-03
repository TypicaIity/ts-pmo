--!strict
--!optimize 2

local lexer = require("lexer")
local parser = require("parser")
local compiler = require("compiler")

local function buf2x(buf: buffer)
    local hex = { "" }
    for i = 0, buffer.len(buf) - 1 do
        table.insert(hex, string.format("%02X", buffer.readu8(buf, i)))

        if (i + 1) % 16 == 0 then
            table.insert(hex, "\n")
        end
    end
    return table.concat(hex, " ")
end

print(buf2x(compiler.compile(parser.parse(lexer.tokenize([[
section .text:
    add rax, rbx
]])))))
