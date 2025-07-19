# TOML Decoder for toml-test

This directory contains a TOML decoder implementation that is compatible with the [toml-test](https://github.com/BurntSushi/toml-test) testing framework.

## Files

- `decoder.lua` - The main TOML decoder that reads TOML from stdin and outputs tagged JSON to stdout
- `encoder.lua` - The main TOML encoder that reads JSON from stdin and outputs TOML to stdout
- `test_decoder.lua` - Test script to verify the decoder works correctly
- `test_encoder.lua` - Test script to verify the encoder works correctly

## Usage

The decoder follows the toml-test interface requirements:

1. **Reads TOML data from stdin**
2. **Outputs tagged JSON to stdout on success**
3. **Returns exit code 0 on success**
4. **Returns exit code 1 and error message to stderr on failure**

### Decoder Example

```bash
# Valid TOML input
echo 'title = "TOML Example"' | lua toml_test/decoder.lua
# Output: {"title":"TOML Example"}

# Invalid TOML input
echo 'invalid = "unclosed string' | lua toml_test/decoder.lua
# Output: Error parsing TOML: At TOML line 1: Single-line string cannot contain line break.
# Exit code: 1
```

### Encoder Example

```bash
# Valid JSON input
echo '{"title": {"type": "string", "value": "TOML Example"}}' | lua toml_test/encoder.lua
# Output: title = "TOML Example"

# Invalid JSON input
echo '{"invalid": "unclosed object' | lua toml_test/encoder.lua
# Output: Error parsing JSON: Unterminated string
# Exit code: 1
```

## Features

The decoder supports all TOML 1.0.0 features:

- **Basic types**: strings, integers, floats, booleans
- **Dates and times**: with proper tagged JSON output
- **Arrays**: both simple arrays and arrays of tables
- **Tables**: nested tables and dotted keys
- **Comments**: both `#` and `//` style comments
- **Error handling**: detailed error messages with line numbers

## Testing

Run the test suites:

```bash
# Test the decoder
lua toml_test/test_decoder.lua

# Test the encoder
lua toml_test/test_encoder.lua
```

These will test various TOML and JSON constructs and verify both the decoder and encoder work correctly.

## Implementation Details

### Decoder
The decoder uses the existing `toml.lua` parser and adds:

1. **JSON encoding**: Custom JSON encoder that handles all TOML types
2. **Tagged JSON**: Datetime values are output as `{"type":"datetime","value":"..."}`
3. **Error handling**: Proper error detection and stderr output
4. **Exit codes**: Correct exit codes for toml-test compatibility

### Encoder
The encoder implements:

1. **JSON parsing**: Custom JSON parser that handles tagged JSON format
2. **Tagged value conversion**: Converts tagged JSON values to appropriate Lua types
3. **TOML encoding**: Uses the existing `TOML.encode` function
4. **Error handling**: Proper error detection and stderr output
5. **Exit codes**: Correct exit codes for toml-test compatibility

## Compatibility

Both the decoder and encoder are designed to be compatible with toml-test and should pass all the standard test cases in the toml-test suite.

### Round-trip Conversion

The decoder and encoder work together to provide round-trip conversion:

```bash
# TOML -> JSON -> TOML
echo 'title = "TOML Example"' | lua toml_test/decoder.lua | lua toml_test/encoder.lua
# Output: title = "TOML Example"
``` 