--!strict
--!optimize 2

local compiler = {}

local parser = require("parser")
local stream = require("stream")
local common = require("common")

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
	REGREG = 0x00,
	REGMEM = 0x01,
	REGIMM = 0x02,
	MEMREG = 0x03
}
local OPIDX: { [string]: number } = {
	["+"] = 0x00,
	["-"] = 0x01
}

local regsize: { [string]: number } = common.regsize
local instructions: { [string]: { operands: number | {number}, types: string } } = common.instructions
local registers: { string } = common.registers

local function _pack(d: { number }, size: number): number
	local a, b, c = unpack(d)
	assert(size == 2 or size == 3, "invalid size")
	assert(rawlen(d) == size and a and b)
	if size == 3 then
		assert(c)
		assert(a >= 0 and a < 4, "a must be in range 0..3")
		assert(b >= 0 and b < 8, "b must be in range 0..7")
		assert(c >= 0 and c < 8, "c must be in range 0..7")

		return bit32.bor(bit32.lshift(a, 6), bit32.lshift(b, 3), c)
	else
		assert(a >= 0 and a < 0x10, "a must be in range 0..15")
		assert(b >= 0 and b < 0x10, "b must be in range 0..15")

		return bit32.bor(bit32.lshift(a, 4), b)
	end
end

local function _unpack(byte: number, size: number): { number }
	assert(size == 2 or size == 3, "invalid size")
	if size == 3 then
		return {
			bit32.band(bit32.rshift(byte, 6), 3),
			bit32.band(bit32.rshift(byte, 3), 7),
			bit32.band(byte, 7),
		}
	else
		return {
			bit32.band(bit32.rshift(byte, 4), 0xF),
			bit32.band(byte, 0xF),
		}
	end
end

local function opcode(mnemonic: string): number
	local i = 1
	for name in instructions do
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
		local metadata: { number } = { 0, 0, 0 } -- placeholder

		local op: number = opcode(insn.data.mnemonic)
		local metadataPos: number = stream:writeu8(0x00)
		stream:writeu8(op)
		
		if op == 43 then     -- ADD
			local modeName: string = ""
			for _, operand in insn.data.operands do
				modeName ..= operand.t
			end
			local mode = OPMODE[modeName]
			assert(mode, "invalid 'ADD' mode")

			if mode == 0x00 then
				local r1: number? = table.find(registers, insn.data.operands[1].v)
				local r2: number? = table.find(registers, insn.data.operands[2].v)
				assert(r1, "invalid register 1")
				assert(r2, "invalid register 2")
				stream:writeu8(r1)
				stream:writeu8(r2)

			elseif mode == 0x01 then
				local reg = table.find(registers, insn.data.operands[1].v)
				local mem = insn.data.operands[2]
				assert(reg, "invalid register")

				local operator: string = string.match(mem.v, "[%+%-]") :: string
				metadata[2] = OPIDX[operator] or 0x00

				stream:writeu8(reg)

				local split: { string } = string.split(mem.v, operator)
				local mreg: number? = table.find(registers, split[1])
				local maddr: number? = tonumber(split[1])
				assert(mreg or maddr, "invalid operand")
				if mreg then
					stream:writeu8(mreg)
					if rawlen(split) == 2 then
						local disp: number? = tonumber(split[2])
						assert(disp, "invalid operand")
						stream:writeu16(disp)
					elseif rawlen(split) ~= 1 then
						assert(false)
					end
				elseif maddr then
					stream:writeu16(maddr)
					if rawlen(split) == 2 then
						local maddr2: number? = tonumber(split[2])
						assert(maddr2, "invalid operand")
						stream:writeu16(maddr2)
					elseif rawlen(split) ~= 1 then
						assert(false)
					end
				end

			elseif mode == 0x02 then
				local r = insn.data.operands[1].v
				assert(table.find(registers, r), "invalid register")
				assert(tonumber(insn.data.operands[2].v), "invalid immediate")

				stream:writeu8(table.find(registers, r) :: number)
				stream["writeu" .. tostring(regsize[r])](stream, tonumber(insn.data.operands[2].v) :: number)
			
			elseif mode == 0x03 then
				assert(nil, "TODO")

			end

			metadata[1] = mode
		elseif op == 07 then -- RET
			local count = #insn.data.operands
			assert(count == 0 or count == 1, "invalid operand amount")
			if count == 1 then
				local bytes = tonumber(insn.data.operands[1].v)
				assert(bytes)
				stream:writeu8(bytes)
			end
			metadata[1] = count
		end

		local old: number = stream:seekg(metadataPos)
		stream:writeu8(_pack(metadata, 3))
		stream:seekg(old)
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
			local old: number = stream:seekg(pos)
			stream:writeu16(size) -- now we do know the size
			stream:seekg(old) -- restore position
		end
	end
	
	return stream.src
end

return compiler
