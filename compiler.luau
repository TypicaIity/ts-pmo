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
	baseStreamSize = 255,
	verbose = false
})

compiler.defaultOptions = DEFAULT_COMPILER_OPTIONS

-- "macros"
local SECTION_SIGNATURE = 0xF7

local function writeSection(data: parser.Tree, options: CompilerOptions): number
	-- ...

	return 0
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
			local size = writeSection(node.body, options)
			local old = stream:seek(pos)
			stream:writeu16(size) -- now we do know the size
			stream:seek(old) -- restore position
		end
	end
	
	return stream.src
end

return compiler
