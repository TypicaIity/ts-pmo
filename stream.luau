--!optimize 2

local stream = { }
stream.__index = stream

export type Stream = {
	src: buffer,
	offset: number,

	writeu8: (self: Stream, v: number) -> number,	   -- write an unsigned 8 bit integer (byte)
	readu8: (self: Stream) -> number, 				   -- read  an unsigned 8 bit integer (byte)
	writeu16: (self: Stream, v: number) -> number,	   -- write an unsigned 16 bit integer (short)
	readu16: (self: Stream) -> number, 				   -- read  an unsigned 16 bit integer (short)

	readstring: (self: Stream) -> string,			   -- read  a null-terminated ASCII string
	writestring: (self: Stream, v: string) -> number,  -- write a null-terminated ASCII string

	seekg: (self: Stream, where: number) -> number, -- moves cursor to where. returns the old offset
	tellg: (self: Stream) -> number,                    -- returns where the cursor is

	expand: (self: Stream, by: number) -> number,				   -- expands self.buf by "by". returns old size
	shrink: (self: Stream, by: number, lossy: boolean?) -> number, -- shrinks self.buf by "by". returns old size
}

function stream.new(size: number): Stream
	return setmetatable({ src = buffer.create(size), offset = 0 }, stream) :: any
end

function stream:writeu8(v: number)
	assert(self.offset + 1 <= buffer.len(self.src), "out of range")
	buffer.writeu8(self.src, self.offset, v)
	self.offset += 1
	return self.offset - 1
end

function stream:readu8()
	assert(self.offset + 1 <= buffer.len(self.src), "out of range")
	local v = buffer.readu8(self.src, self.offset)
	self.offset += 1
	return v
end

function stream:writeu16(v: number)
	assert(self.offset + 2 <= buffer.len(self.src), "out of range")
	buffer.writeu16(self.src, self.offset, v)
	self.offset += 2
	return self.offset - 2
end

function stream:readu16()
	assert(self.offset + 2 <= buffer.len(self.src), "out of range")
	local v = buffer.readu16(self.src, self.offset)
	self.offset += 2
	return v
end

function stream:writeu32(v: number): number
	assert(self.offset + 4 <= buffer.len(self.src), "out of range")
	buffer.writeu32(self.src, self.offset, v)
	self.offset += 4
	return self.offset - 4
end

function stream:readu32()
	assert(self.offset + 4 <= buffer.len(self.src), "out of range")
	local v = buffer.readu32(self.src, self.offset)
	self.offset += 4
	return v
end

function stream:seekg(where: number): number
	assert(where <= buffer.len(self.src) and where >= 0, "out of range")
	local old = self.offset
	self.offset = where
	return old
end

function stream:tellg(): number
	return self.offset
end

function stream:writestring(v: string): number
	v ..= "\0\0"
	assert(self.offset + string.len(v) <= buffer.len(self.src), "out of range")
	local old = self.offset
	buffer.writestring(self.src, self.offset, v)
	self.offset += string.len(v)
	return old
end

function stream:readstring(): string
	local str = ""
	while self.offset < buffer.len(self.src) do
		local char = string.char(buffer.readu8(self.src, self.offset))
		self.offset += 1
		if char == "\0" then
			local nextChar = string.char(buffer.readu8(self.src, self.offset))
			if nextChar == "\0" then
				self.offset += 1
				return str
			end
			str ..= char
		else
			str ..= char
		end
	end
	assert(false)
end

function stream:expand(by: number): number
	assert(by > 0, "use :shrink to shrink the buffer")
	local size: number = buffer.len(self.src)
	local new: buffer = buffer.create(size + by)
	buffer.copy(new, 0, self.buf)
	self.src = new
	return size
end

function stream:shrink(by: number, lossy: boolean?): number
	assert(by > 0, "use :expand to expand the buffer")
	local size: number = buffer.len(self.src)
	assert(lossy or by < size, "data loss")
	local new: buffer = buffer.create(size - by)
	buffer.copy(new, 0, self.buf)
	self.src = new
	return size
end

return stream
