package = "toml2lua"
version = "3.0.0-1"
source = {
	url = "git://github.com/nexo-tech/toml2lua.git",
	tag = "v3.0.0",
}
description = {
	summary = "TOML 1.0.0 compliant decoder/encoder for Lua (lua-toml fork)",
	detailed = [[
A battle-tested, zero-dependency TOML parser/encoder for Lua that actually works.
Built for developers who need config files that don't break at 3AM.

Features:
- Full TOML 1.0.0 compliance
- Zero dependencies
- Streaming parser support
- Strict and relaxed modes
- Comprehensive test suite
- Cross-version Lua compatibility (5.1+)

Serializes TOML into Lua tables and Lua tables into TOML.]],
	homepage = "https://github.com/nexo-tech/toml2lua",
	license = "MIT",
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin",
	modules = {
		toml = "toml.lua",
	},
	copy_directories = {"spec"},
}
