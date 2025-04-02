--!strict
--!optimize 2

local compiler = {}

local parser = require("parser")
local stream = require("stream")

export type CompilerOptions = {
	baseStreamSize: number,		-- the base stream size of the bytecode
	verbose: boolean            -- log detailed information          -- TODO
}

local DEFAULT_COMPILER_OPTIONS: CompilerOptions = table.freeze({
	baseStreamSize = 32,
	verbose = false
})

compiler.defaultOptions = DEFAULT_COMPILER_OPTIONS

-- "macros"
local SECTION_SIGNATURE = 0xF7
local OPMODE: { [string]: number } = {
	REGREG = 0x01,
	REGMEM = 0x02,
	REGIMM = 0x03,
	MEMREG = 0x04,
	MEMIMM = 0x05
}

local function opcode(mnemonic: string): number
	local i = 1
	for name in parser.instructions do
		if name == mnemonic then
			return i
		end
		i += 1
	end
	assert()
end

local function writeSection(stream: stream.Stream, data: parser.Tree, options: CompilerOptions): number
	local start: number = stream.offset

	for _, insn in data do
		local metadata: number = 0x00

		local op: number = opcode(insn.data.mnemonic)
		local metadataPos: number = stream:writeu8(metadata)
		stream:writeu8(op)
		
		if op == 43 then -- ADD
			local modeName: string = ""
			for _, operand in insn.data.operands do
				modeName ..= operand.t
			end
			local mode = OPMODE[modeName]
			assert(mode)

			if mode == 0x03 then -- REGIMM
				stream:writeu8(table.find(parser.registers, insn.data.operands[1].v) :: number)
				stream:writeu16(tonumber(insn.data.operands[2].v) :: number)
			end

			metadata = mode
		end

		local old: number = stream:seek(metadataPos)
		stream:writeu8(metadata)
		stream:seek(old)
	end

	return stream.offset - start
end

function compiler.compile(ast: parser.Tree, options: CompilerOptions?): buffer
	options = options or DEFAULT_COMPILER_OPTIONS -- use default options if none r provided
	assert(options ~= nil)

	local stream: stream.Stream = stream.new(options.baseStreamSize)

	for _, node in ast do
		if node.t == "SECTION" and node.body then
			stream:writeu8(SECTION_SIGNATURE)
			stream:writestring(node.data.name)
			local pos: number = stream:writeu16(0) -- we dont know the size yet
			local size: number = writeSection(stream, node.body, options)
			local old: number = stream:seek(pos)
			stream:writeu16(size) -- now we do know the size
			stream:seek(old) -- restore position
		end
	end
	
	return stream.src
end

return compiler
