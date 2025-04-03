--!strict
--!optimize 2

local common = {}

common.registers = {
	"rax", "rbx", "rcx", "rdx", "rsp", "rip", "rbp", "rsi", "rdi",
	"r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",

	"eax", "ebx", "ecx", "edx", "esp", "eip", "ebp", "esi", "edi",

	"flags"
}

common.instructions = {
	["mov"] = {operands = 2, types = "IMM|REG|MEM"},
	["call"] = {operands = 1, types = "IMM|REG|MEM"},
	["jmp"] = {operands = 1, types = "IMM|REG|MEM"},
	["cmp"] = {operands = 2, types = "IMM|REG|MEM"},
	["add"] = {operands = 2, types = "IMM|REG|MEM"},
	["sub"] = {operands = 2, types = "IMM|REG|MEM"},
	["mul"] = {operands = 2, types = "IMM|REG|MEM"},
	["div"] = {operands = 2, types = "IMM|REG|MEM"},
	["inc"] = {operands = 1, types = "REG|MEM"},
	["dec"] = {operands = 1, types = "REG|MEM"},
	["and"] = {operands = 2, types = "IMM|REG|MEM"},
	["or"] = {operands = 2, types = "IMM|REG|MEM"},
	["xor"] = {operands = 2, types = "IMM|REG|MEM"},
	["not"] = {operands = 1, types = "REG|MEM"},
	["shl"] = {operands = 2, types = "IMM|REG|MEM"},
	["shr"] = {operands = 2, types = "IMM|REG|MEM"},
	["nop"] = {operands = 0, types = ""},
	["ret"] = {operands = {0, 1}, types = "IMM"},
	["push"] = {operands = 1, types = "REG|MEM"},
	["pop"] = {operands = 1, types = "REG|MEM"},
	["test"] = {operands = 2, types = "IMM|REG|MEM"},
	["lea"] = {operands = 2, types = "REG|MEM"},
	["imul"] = {operands = 2, types = "IMM|REG|MEM"},
	["idiv"] = {operands = 2, types = "IMM|REG|MEM"},
	["fld"] = {operands = 1, types = "MEM"},
	["fst"] = {operands = 1, types = "MEM"},
	["fstp"] = {operands = 1, types = "MEM"},
	["fadd"] = {operands = 1, types = "MEM"},
	["fsub"] = {operands = 1, types = "MEM"},
	["fmul"] = {operands = 1, types = "MEM"},
	["fdiv"] = {operands = 1, types = "MEM"},
	["fcom"] = {operands = 1, types = "MEM"},
	["fcomp"] = {operands = 1, types = "MEM"},
	["fxch"] = {operands = 1, types = "REG"},
	["fchs"] = {operands = 0, types = ""},
	["fabs"] = {operands = 0, types = ""},
	["fsin"] = {operands = 0, types = ""},
	["fcos"] = {operands = 0, types = ""},
	["fptan"] = {operands = 0, types = ""},
	["f2xm1"] = {operands = 0, types = ""},
	["cli"] = {operands = 0, types = ""},
	["hlt"] = {operands = 0, types = ""},
	["int"] = {operands = 1, types = "IMM"}
}

common.regsize = {
    -- buffer and bit32 dont support 64 bit numbers
	rax = 32, rbx = 32, rcx = 32, rdx = 32, rsp = 32, rip = 32, rbp = 32, rsi = 32, rdi = 32,
	r8 = 32, r9 = 32, r10 = 32, r11 = 32, r12 = 32, r13 = 32, r14 = 32, r15 = 32,

	eax = 32, ebx = 32, ecx = 32, esp = 32, eip = 32, ebp = 32, esi = 32, edi = 32,

	flags = 16
}

return common
