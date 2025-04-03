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

-- constants
local SECTION_SIGNATURE: number = 0xF7
local OPMODE: { [string]: number } = {
	REGREG = 0x01,
	REGMEM = 0x02,
	REGIMM = 0x03,
	MEMREG = 0x04,
	MEMIMM = 0x05
}

local regsize: { [string]: number } = {
    -- buffer and bit32 dont support 64 bit numbers
	rax = 32, rbx = 32, rcx = 32, rdx = 32, rsp = 32, rip = 32, rbp = 32, rsi = 32, rdi = 32,
	r8 = 32, r9 = 32, r10 = 32, r11 = 32, r12 = 32, r13 = 32, r14 = 32, r15 = 32,

	eax = 32, ebx = 32, ecx = 32, esp = 32, eip = 32, ebp = 32, esi = 32, edi = 32,

	flags = 16
}

local function opcode(mnemonic: string): number
	local i = 1
	for name in parser.instructions do
		if name == mnemonic then
			return i
		end
		i += 1
	end
	assert(false)
end

local function writeSection(stream: stream.Stream, data: parser.Tree, options: CompilerOptions): number
	local start: number = stream.offset

	for _, insn in data do
		local metadata: number = 0x00 -- placeholder

		local op: number = opcode(insn.data.mnemonic)
		local metadataPos: number = stream:writeu8(metadata)
		stream:writeu8(op)
		
		if op == 43 then     -- ADD
			local modeName: string = ""
			for _, operand in insn.data.operands do
				modeName ..= operand.t
			end
			local mode = OPMODE[modeName]
			assert(mode, "invalid 'add' mode")

			if mode == 0x03 then -- REGIMM
				local r = insn.data.operands[1].v
				stream:writeu8(table.find(parser.registers, r) :: number)
				stream["writeu" .. tostring(regsize[r])](stream, tonumber(insn.data.operands[2].v) :: number)
			end

			metadata = mode
		elseif op == 07 then -- RET
			local count = #insn.data.operands
			assert(count == 0 or count == 1, "invalid operand amount")
			if count == 1 then
				local bytes = tonumber(insn.data.operands[1].v)
				assert(bytes)
				stream:writeu8(bytes)
			end
			metadata = count
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
