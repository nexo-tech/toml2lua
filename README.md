# toml2lua

[![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.0.0-orange.svg)](https://github.com/nexo-tech/toml2lua)

> **TOML parsing that doesn't suck** 🚀

A battle-tested, zero-dependency TOML parser/encoder for Lua that actually works. Built for developers who need config files that don't break at 3AM.

## 🎯 Why This Exists

Config files should be simple. But when you're building systems that scale, you need something that:
- **Actually parses TOML correctly** (looking at you, other libraries)
- **Handles edge cases** without exploding
- **Works across Lua versions** (5.1+)
- **Doesn't require 47 dependencies**

This is that library.

## 🚀 Quick Start

```lua
local TOML = require "toml"

-- Parse TOML into Lua tables
local config = TOML.parse([[
[database]
host = "localhost"
port = 5432
ssl = true

[redis]
url = "redis://cache:6379"
timeout = 30.5

[[servers]]
name = "alpha"
ip = "10.0.0.1"

[[servers]]
name = "beta" 
ip = "10.0.0.2"
]])

-- Encode Lua tables back to TOML
local toml_string = TOML.encode({
    app = {
        name = "my-awesome-app",
        version = "1.0.0",
        features = {"auth", "caching", "api"}
    }
})
```

## 🧪 What It Handles

### ✅ Full TOML 1.0.0 Support
- **All data types**: strings, integers, floats, booleans, dates, arrays, tables
- **Advanced features**: table arrays, inline tables, multiline strings
- **Date/time precision**: Local dates, times, datetimes with timezone support
- **Special floats**: `inf`, `-inf`, `nan` values

### 🔧 Developer-Friendly Features
- **Strict mode** (default) - follows TOML spec exactly
- **Relaxed mode** - allows mixed arrays and other Lua-friendly features
- **Streaming parser** - process large files in chunks
- **Error handling** - clear error messages when things go wrong

### 🛡️ Battle-Tested
- **200+ test cases** covering edge cases and real-world scenarios
- **TOML test suite** compatibility
- **Used in production** by teams that can't afford config failures

## 📖 API Reference

### Basic Usage

```lua
-- Parse TOML string
local data, err = TOML.parse(toml_string)
if err then
    print("Parse error:", err)
    return
end

-- Encode Lua table to TOML
local toml_string = TOML.encode(lua_table)
```

### Streaming Parser

```lua
-- For large files or streaming data
local parser = TOML.multistep_parser()
parser(chunk_1)
parser(chunk_2)
-- ...
local result = parser() -- Get final result
```

### Configuration Options

```lua
-- Relaxed mode for Lua-friendly features
TOML.strict = false

-- Or per-parse
local data = TOML.parse(toml_string, {strict = false})

-- Or with streaming parser
local parser = TOML.multistep_parser{strict = false}
```

## 🎨 Real-World Examples

### Application Config
```lua
local config = TOML.parse([[
[app]
name = "my-api"
version = "2.1.0"
debug = false

[app.features]
auth = true
caching = true
rate_limiting = false

[database]
host = "db.internal"
port = 5432
ssl = true
pool_size = 20
timeout = 30.5

[redis]
url = "redis://cache:6379"
max_connections = 100

[[servers]]
name = "web-1"
host = "10.0.0.1"
port = 8080

[[servers]]
name = "web-2" 
host = "10.0.0.2"
port = 8080
]])
```

### Complex Data Structures
```lua
-- Nested tables, arrays, and mixed types
local data = {
    project = {
        name = "awesome-project",
        metadata = {
            created = {year = 2024, month = 1, day = 15},
            tags = {"lua", "toml", "config"}
        },
        dependencies = {
            {name = "lua-http", version = "0.4"},
            {name = "lua-cjson", version = "2.1"}
        }
    }
}

local toml = TOML.encode(data)
```

## 🔧 Installation

### Via LuaRocks
```bash
luarocks install toml2lua
```

### Manual Installation
```bash
git clone https://github.com/nexo-tech/toml2lua.git
cd toml2lua
# Copy toml.lua to your project
```

## 🧪 Testing

Run the full test suite:
```bash
# Install busted if you haven't
luarocks install busted

# Run tests
busted spec/
```

## 🤝 Contributing

Found a bug? Have a feature request? 

1. **Check existing issues** first
2. **Add a test case** that demonstrates the problem
3. **Submit a PR** with a clear description

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔄 About This Fork

This is a fork of the original [jonstoler/lua-toml](https://github.com/jonstoler/lua-toml) repository, which became unmaintained. We've merged various community contributions and added new fixes and improvements to keep this essential library alive and up-to-date.

### Original Contributors

- **[Jonathan Stoler](https://github.com/jonstoler)** - Original author and maintainer
- **[Natanael Copa](https://github.com/ncopa)** - Fix encoding of plain arrays (issue [#12](https://github.com/jonstoler/lua-toml/issues/12))
- **[Luka Vandervelden](https://github.com/Lukc)** - Lua 5.1 support in rockspec (issue [#20](https://github.com/jonstoler/lua-toml/issues/20))
- **[Ekaterina Vaartis](https://github.com/vaartis)** - Fix path encoding issues
- **[pocomane](https://github.com/pocomane)** - Multiple bug fixes and improvements:
  - [#11](https://github.com/jonstoler/lua-toml/issues/11)
  - [#17](https://github.com/jonstoler/lua-toml/issues/17)
  - [#18](https://github.com/jonstoler/lua-toml/issues/18)
  - [#22](https://github.com/jonstoler/lua-toml/issues/22)
  - [#23](https://github.com/jonstoler/lua-toml/issues/23)

### Current Maintainer

**[Oleg Pustovit](https://github.com/nexo-tech)** - Fork maintainer, merging community contributions and adding new features.

---

**Built for developers who care about their config files.** 🚀
