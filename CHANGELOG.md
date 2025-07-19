# 3.0.0

- upgrade to TOML v1.0.0 specification compliance
- add support for hexadecimal, octal, and binary number formats
- enhance array handling with nested arrays and mixed type support
- improve error handling for unterminated strings, missing brackets, and invalid keys
- add toml-test compatibility with new value type creators and conversion functions
- enhance encoding/decoding for string arrays, escape sequences, and quoted keys
- fix issues [#18](https://github.com/jonstoler/lua-toml/issues/18), [#27](https://github.com/jonstoler/lua-toml/issues/27), [#28](https://github.com/jonstoler/lua-toml/issues/28), [#29](https://github.com/jonstoler/lua-toml/issues/29)
- improve comment handling and encoding consistency
- add comprehensive date validation and special float value handling

# 2.0.1

- fix [#16](https://github.com/jonstoler/lua-toml/issues/16) by using the correct definition of CRLF newline
  - this unfortunately introduces [#17](https://github.com/jonstoler/lua-toml/issues/17), which was previously undiscovered

# 2.0.0

- switch to MIT license

# 1.0.1

- indicate support for TOML 0.4.0 via `TOML.version`
- fix encoding of simple arrays
- indicate support for Lua 5.1 in LuaRocks

# 1.0.0

- support TOML 0.4.0
