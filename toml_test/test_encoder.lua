#!/usr/bin/env lua

-- Test script for the TOML encoder
local function test_encoder()
    local test_cases = {
        {
            name = "Simple string",
            input = '{"title": {"type": "string", "value": "TOML Example"}}',
            expected_contains = 'title = "TOML Example"'
        },
        {
            name = "Numbers and booleans",
            input = '{"number": {"type": "integer", "value": "42"}, "float": {"type": "float", "value": "3.14"}, "bool": {"type": "bool", "value": "true"}}',
            expected_contains = 'number = 42'
        },
        {
            name = "Arrays",
            input = '{"colors": [{"type": "string", "value": "red"}, {"type": "string", "value": "yellow"}, {"type": "string", "value": "green"}]}',
            expected_contains = 'colors ='
        },
        {
            name = "Tables",
            input = '{"database": {"server": {"type": "string", "value": "192.168.1.1"}, "ports": [{"type": "integer", "value": "8001"}, {"type": "integer", "value": "8002"}]}}',
            expected_contains = 'database'
        },
        {
            name = "Datetime",
            input = '{"date": {"type": "datetime", "value": "1979-05-27T07:32:00Z"}}',
            expected_contains = 'date ='
        },
        {
            name = "Array of tables",
            input = '{"fruits": [{"name": {"type": "string", "value": "apple"}}, {"name": {"type": "string", "value": "banana"}}]}',
            expected_contains = 'fruits'
        }
    }
    
    print("Testing TOML encoder...")
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
        
        -- Run the encoder
        local handle = io.popen("lua toml_test/encoder.lua < " .. temp_file)
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
    
    -- Test error cases
    print("Testing error cases...")
    print("-" .. string.rep("-", 50))
    
    local error_cases = {
        {
            name = "Invalid JSON",
            input = '{"invalid": "unclosed object',
            should_fail = true
        },
        {
            name = "Unknown tagged type",
            input = '{"invalid": {"type": "unknown", "value": "test"}}',
            should_fail = true
        }
    }
    
    for _, test in ipairs(error_cases) do
        print("Testing: " .. test.name)
        
        -- Create a temporary file with the test input
        local temp_file = os.tmpname()
        local f = io.open(temp_file, "w")
        f:write(test.input)
        f:close()
        
        -- Run the encoder
        local handle = io.popen("lua toml_test/encoder.lua < " .. temp_file)
        local output = handle:read("*a")
        local status = handle:close()
        
        -- Clean up temp file
        os.remove(temp_file)
        
        -- Check result
        if test.should_fail and not status then
            print("  ✓ PASS (correctly failed)")
            passed = passed + 1
        elseif not test.should_fail and status then
            print("  ✓ PASS")
            passed = passed + 1
        else
            print("  ✗ FAIL")
            print("    Expected to " .. (test.should_fail and "fail" or "succeed"))
            print("    Got: " .. (status and "success" or "failure"))
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
if test_encoder() then
    os.exit(0)
else
    os.exit(1)
end 