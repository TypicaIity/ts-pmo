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
local registers: { string } = common.registers

local _unpack = common._unpack
local _pack   = common._pack
local opcode  = common.opcode

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
