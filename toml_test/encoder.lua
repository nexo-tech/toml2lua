#!/usr/bin/env lua

-- TOML encoder for toml-test compatibility
-- Reads JSON from stdin, outputs TOML to stdout

local TOML = require("toml")

-- Simple JSON decoder for parsing tagged JSON input
local function decode_json(str)
    local i = 1
    
    -- Forward declarations
    local parse_value, parse_object, parse_array
    
    local function skip_whitespace()
        while i <= #str and str:sub(i, i):match("%s") do
            i = i + 1
        end
    end
    
    local function parse_string()
        if str:sub(i, i) ~= '"' then
            error("Expected string at position " .. i)
        end
        i = i + 1
        local result = ""
        while i <= #str do
            local c = str:sub(i, i)
            if c == '"' then
                i = i + 1
                return result
            elseif c == '\\' then
                i = i + 1
                if i > #str then
                    error("Unexpected end of string")
                end
                local next_c = str:sub(i, i)
                if next_c == '"' or next_c == '\\' or next_c == '/' then
                    result = result .. next_c
                elseif next_c == 'b' then
                    result = result .. '\b'
                elseif next_c == 'f' then
                    result = result .. '\f'
                elseif next_c == 'n' then
                    result = result .. '\n'
                elseif next_c == 'r' then
                    result = result .. '\r'
                elseif next_c == 't' then
                    result = result .. '\t'
                else
                    error("Invalid escape sequence \\" .. next_c)
                end
            else
                result = result .. c
            end
            i = i + 1
        end
        error("Unterminated string")
    end
    
    local function parse_number()
        local start = i
        if str:sub(i, i) == '-' then
            i = i + 1
        end
        while i <= #str and str:sub(i, i):match("%d") do
            i = i + 1
        end
        if str:sub(i, i) == '.' then
            i = i + 1
            while i <= #str and str:sub(i, i):match("%d") do
                i = i + 1
            end
        end
        if str:sub(i, i) == 'e' or str:sub(i, i) == 'E' then
            i = i + 1
            if str:sub(i, i) == '+' or str:sub(i, i) == '-' then
                i = i + 1
            end
            while i <= #str and str:sub(i, i):match("%d") do
                i = i + 1
            end
        end
        local num_str = str:sub(start, i - 1)
        local num = tonumber(num_str)
        if not num then
            error("Invalid number: " .. num_str)
        end
        return num
    end
    
    parse_object = function()
        if str:sub(i, i) ~= '{' then
            error("Expected object at position " .. i)
        end
        i = i + 1
        local result = {}
        
        skip_whitespace()
        if str:sub(i, i) == '}' then
            i = i + 1
            return result
        end
        
        while true do
            skip_whitespace()
            if str:sub(i, i) ~= '"' then
                error("Expected key at position " .. i)
            end
            local key = parse_string()
            
            skip_whitespace()
            if str:sub(i, i) ~= ':' then
                error("Expected ':' at position " .. i)
            end
            i = i + 1
            
            local value = parse_value()
            result[key] = value
            
            skip_whitespace()
            if str:sub(i, i) == '}' then
                i = i + 1
                return result
            elseif str:sub(i, i) == ',' then
                i = i + 1
            else
                error("Expected ',' or '}' at position " .. i)
            end
        end
    end
    
    parse_array = function()
        if str:sub(i, i) ~= '[' then
            error("Expected array at position " .. i)
        end
        i = i + 1
        local result = {}
        
        skip_whitespace()
        if str:sub(i, i) == ']' then
            i = i + 1
            return result
        end
        
        while true do
            local value = parse_value()
            table.insert(result, value)
            
            skip_whitespace()
            if str:sub(i, i) == ']' then
                i = i + 1
                return result
            elseif str:sub(i, i) == ',' then
                i = i + 1
            else
                error("Expected ',' or ']' at position " .. i)
            end
        end
    end
    
    parse_value = function()
        skip_whitespace()
        local c = str:sub(i, i)
        
        if c == '"' then
            return parse_string()
        elseif c == '{' then
            return parse_object()
        elseif c == '[' then
            return parse_array()
        elseif c == 't' and str:sub(i, i + 3) == "true" then
            i = i + 4
            return true
        elseif c == 'f' and str:sub(i, i + 4) == "false" then
            i = i + 5
            return false
        elseif c == 'n' and str:sub(i, i + 3) == "null" then
            i = i + 4
            return nil
        elseif c == '-' or c:match("%d") then
            return parse_number()
        else
            error("Unexpected character: " .. c .. " at position " .. i)
        end
    end
    
    local result = parse_value()
    skip_whitespace()
    if i <= #str then
        error("Unexpected characters after JSON")
    end
    return result
end

-- Convert tagged JSON values to Lua values
local function convert_tagged_value(tagged_obj)
    if type(tagged_obj) == "table" and tagged_obj.type and tagged_obj.value then
        local value_type = tagged_obj.type
        local value_str = tagged_obj.value
        
        if value_type == "string" then
            return value_str
        elseif value_type == "integer" then
            local num = tonumber(value_str)
            if not num or num ~= math.floor(num) then
                error("Invalid integer: " .. value_str)
            end
            return num
        elseif value_type == "float" then
            local num = tonumber(value_str)
            if not num then
                error("Invalid float: " .. value_str)
            end
            return num
        elseif value_type == "bool" then
            if value_str == "true" then
                return true
            elseif value_str == "false" then
                return false
            else
                error("Invalid boolean: " .. value_str)
            end
        elseif value_type == "datetime" or value_type == "datetime-local" or value_type == "date-local" or value_type == "time-local" then
            -- Parse datetime string and create a date table
            local date_table = {}
            
            -- Handle different datetime formats
            if value_type == "datetime" then
                -- RFC 3339 format: 1979-05-27T07:32:00Z or 1979-05-27T07:32:00-07:00
                local year, month, day, hour, min, sec, zone = value_str:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)(.*)$")
                if year then
                    date_table.year = tonumber(year)
                    date_table.month = tonumber(month)
                    date_table.day = tonumber(day)
                    date_table.hour = tonumber(hour)
                    date_table.min = tonumber(min)
                    date_table.sec = tonumber(sec)
                    
                    -- Parse timezone
                    if zone == "Z" then
                        date_table.zone = 0
                    elseif zone:match("^[+-]%d+:%d+$") then
                        local sign, zh, zm = zone:match("^([+-])(%d+):(%d+)$")
                        local zone_hours = tonumber(zh)
                        if sign == "-" then
                            zone_hours = -zone_hours
                        end
                        date_table.zone = zone_hours
                    end
                end
            elseif value_type == "datetime-local" then
                -- RFC 3339 without timezone: 1979-05-27T07:32:00
                local year, month, day, hour, min, sec = value_str:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)$")
                if year then
                    date_table.year = tonumber(year)
                    date_table.month = tonumber(month)
                    date_table.day = tonumber(day)
                    date_table.hour = tonumber(hour)
                    date_table.min = tonumber(min)
                    date_table.sec = tonumber(sec)
                end
            elseif value_type == "date-local" then
                -- Date only: 1979-05-27
                local year, month, day = value_str:match("^(%d+)-(%d+)-(%d+)$")
                if year then
                    date_table.year = tonumber(year)
                    date_table.month = tonumber(month)
                    date_table.day = tonumber(day)
                end
            elseif value_type == "time-local" then
                -- Time only: 07:32:00
                local hour, min, sec = value_str:match("^(%d+):(%d+):(%d+)$")
                if hour then
                    date_table.hour = tonumber(hour)
                    date_table.min = tonumber(min)
                    date_table.sec = tonumber(sec)
                end
            end
            
            if next(date_table) then
                return TOML.datefy(date_table)
            else
                error("Invalid datetime format: " .. value_str)
            end
        else
            error("Unknown tagged type: " .. value_type)
        end
    end
    
    return tagged_obj
end

-- Recursively convert tagged JSON structure to Lua structure
local function convert_json_structure(data)
    if type(data) == "table" then
        -- Check if this is a tagged value
        if data.type and data.value then
            return convert_tagged_value(data)
        end
        
        -- Check if this is an array
        local is_array = true
        local max_index = 0
        for k, v in pairs(data) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                is_array = false
                break
            end
            if k > max_index then
                max_index = k
            end
        end
        
        if is_array and max_index > 0 then
            -- It's an array
            local result = {}
            for i = 1, max_index do
                result[i] = convert_json_structure(data[i])
            end
            return result
        else
            -- It's an object
            local result = {}
            for k, v in pairs(data) do
                result[k] = convert_json_structure(v)
            end
            return result
        end
    end
    
    return data
end

-- Main encoder function
local function main()
    -- Read JSON from stdin
    local json_data = ""
    while true do
        local line = io.read("*line")
        if not line then
            break
        end
        json_data = json_data .. line .. "\n"
    end
    
    -- Parse JSON
    local success, parsed_json = pcall(decode_json, json_data)
    if not success then
        io.stderr:write("Error parsing JSON: " .. tostring(parsed_json) .. "\n")
        os.exit(1)
    end
    
    -- Convert tagged JSON structure to Lua structure
    local success, lua_data = pcall(convert_json_structure, parsed_json)
    if not success then
        io.stderr:write("Error converting JSON structure: " .. tostring(lua_data) .. "\n")
        os.exit(1)
    end
    
    -- Encode to TOML
    local success, toml_output = pcall(TOML.encode, lua_data)
    if not success then
        io.stderr:write("Error encoding TOML: " .. tostring(toml_output) .. "\n")
        os.exit(1)
    end
    
    -- Output TOML to stdout
    io.write(toml_output .. "\n")
    os.exit(0)
end

-- Run the encoder
main()
