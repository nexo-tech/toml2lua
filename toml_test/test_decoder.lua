#!/usr/bin/env lua

-- Test script for the TOML decoder
local function test_decoder()
    local test_cases = {
        {
            name = "Simple key-value",
            input = 'title = "TOML Example"',
            expected_contains = '"title":"TOML Example"'
        },
        {
            name = "Numbers and booleans",
            input = 'number = 42\nfloat = 3.14\nbool = true',
            expected_contains = '"number":42'
        },
        {
            name = "Arrays",
            input = 'colors = ["red", "yellow", "green"]',
            expected_contains = '"colors"'
        },
        {
            name = "Tables",
            input = '[database]\nserver = "192.168.1.1"\nports = [8001, 8002]',
            expected_contains = '"database"'
        },
        {
            name = "Datetime",
            input = 'date = 1979-05-27T07:32:00Z',
            expected_contains = '"type":"datetime"'
        },
        {
            name = "Array of tables",
            input = '[[fruits]]\nname = "apple"\n\n[[fruits]]\nname = "banana"',
            expected_contains = '"fruits"'
        }
    }
    
    print("Testing TOML decoder...")
    print("=" .. string.rep("=", 50))
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(test_cases) do
        print("Testing: " .. test.name)
        
        -- Create a temporary file with the test input
        local temp_file = os.tmpname()
        local f = io.open(temp_file, "w")
        f:write(test.input)
        f:close()
        
        -- Run the decoder
        local handle = io.popen("lua toml_test/decoder.lua < " .. temp_file)
        local output = handle:read("*a")
        local status = handle:close()
        
        -- Clean up temp file
        os.remove(temp_file)
        
        -- Check result
        local clean_output = output:gsub("\n", "")
        local found = clean_output:find(test.expected_contains)
        if status and found ~= nil then
            print("  ✓ PASS")
            passed = passed + 1
        else
            print("  ✗ FAIL")
            print("    Expected to contain: " .. test.expected_contains)
            print("    Got: " .. clean_output)
            print("    Found at position: " .. tostring(found))
            failed = failed + 1
        end
        print()
    end
    
    print("=" .. string.rep("=", 50))
    print("Results: " .. passed .. " passed, " .. failed .. " failed")
    
    if failed == 0 then
        print("All tests passed! ✓")
        return true
    else
        print("Some tests failed! ✗")
        return false
    end
end

-- Run the tests
if test_decoder() then
    os.exit(0)
else
    os.exit(1)
end 