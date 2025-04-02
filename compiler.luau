--!strict
--!optimize 2

local compiler = {}

local parser = require("parser")
local stream = require("stream")

export type CompilerOptions = {
	baseStreamSize: number
}

local DEFAULT_COMPILER_OPTIONS: CompilerOptions = table.freeze({
	baseStreamSize = 255
})
compiler.defaultOptions = DEFAULT_COMPILER_OPTIONS

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
			local pos: number = stream:writeu16(0) -- we dont know the size yet
			stream:writestring(node.data.name)
			local size = writeSection(node.body, options)
			local old = stream:seek(pos)
			stream:writeu16(size) -- update size
			stream:seek(old) -- move back
		end
	end
	
	return stream.src
end

return compiler
