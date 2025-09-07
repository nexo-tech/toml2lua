# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

toml2lua is a zero-dependency TOML 1.0.0 parser/encoder for Lua that supports all Lua versions 5.1+. It's a fork of jonstoler/lua-toml with community contributions and active maintenance.

## Core Architecture

- **Single module**: `toml.lua` (1767 lines) contains the entire parser/encoder implementation
- **Parser structure**: Recursive descent parser with streaming support via `multistep_parser()`
- **Encoding/Decoding**: Bidirectional conversion between TOML and Lua tables
- **Modes**: Strict mode (TOML spec compliant) and relaxed mode (Lua-friendly features)
- **Test compatibility**: Full integration with toml-test framework for validation

## Key APIs

- `TOML.parse(toml_string, options)` - Parse TOML to Lua tables
- `TOML.encode(lua_table)` - Encode Lua tables to TOML
- `TOML.multistep_parser(options)` - Streaming parser for large files
- `TOML.strict` - Global strictness flag (default: true)

## Development Commands

### Testing
```bash
# Install busted test framework
luarocks install busted

# Run all tests
busted spec/

# Run specific test file
busted spec/string_spec.lua
```

### TOML Compliance Testing
```bash
# Install toml-test (requires Go)
GOBIN=$(pwd) go install github.com/toml-lang/toml-test/cmd/toml-test@latest

# Run decoder tests
./toml-test ./toml_test/decoder.lua 2>&1 | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g' > results.txt

# Test individual components
lua toml_test/test_decoder.lua
lua toml_test/test_encoder.lua
```

### Installation
```bash
# Via LuaRocks
luarocks install toml2lua

# Local development
luarocks make toml2lua-3.0.0-1.rockspec
```

## Test Organization

The `spec/` directory contains 25+ test files covering:
- Basic types (string, integer, float, bool)
- Complex structures (arrays, tables, table-arrays)
- Edge cases (empty values, mixed arrays, comments)
- Error handling and validation
- Encoding/decoding round-trip tests
- TOML version compatibility

## Key Implementation Details

- **Date/time handling**: Supports local dates, times, datetimes with timezone precision
- **Special float values**: Handles `inf`, `-inf`, `nan` according to TOML spec
- **Array handling**: Supports both homogeneous (strict) and mixed (relaxed) arrays
- **Table resolution**: Handles dotted keys, nested tables, and table arrays
- **Error reporting**: Line-number accurate error messages with context

## toml-test Integration

The `toml_test/` directory provides compatibility with the official TOML test suite:
- **decoder.lua**: Reads TOML from stdin, outputs tagged JSON
- **encoder.lua**: Reads tagged JSON from stdin, outputs TOML
- **Tagged JSON format**: Uses `{"type": "...", "value": "..."}` for type preservation