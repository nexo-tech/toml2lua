#!/usr/bin/env lua

-- TOML decoder for toml-test compatibility
-- Reads TOML from stdin, outputs tagged JSON to stdout

local TOML = require("toml")

-- Simple JSON encoder for tagged JSON output
local function encode_json(value)
    local t = type(value)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "number" then
        if value == math.floor(value) then
            return string.format("%d", value)
        else
            return string.format("%.10g", value)
        end
    elseif t == "string" then
        -- Escape string for JSON
        local escaped = value:gsub("\\", "\\\\")
                           :gsub("\"", "\\\"")
                           :gsub("\b", "\\b")
                           :gsub("\f", "\\f")
                           :gsub("\n", "\\n")
                           :gsub("\r", "\\r")
                           :gsub("\t", "\\t")
        return '"' .. escaped .. '"'
    elseif t == "table" then
        -- Check if it's a date (has metatable)
        if TOML.isdate(value) then
            -- Format as ISO 8601 datetime
            local rep = ''
            if value.year then
                rep = rep .. string.format("%04d-%02d-%02d", value.year, value.month, value.day)
            end
            if value.hour then
                if value.year then
                    rep = rep .. 'T'
                end
                rep = rep .. string.format("%02d:%02d:", value.hour, value.min)
                local sec, frac = math.modf(value.sec)
                rep = rep .. string.format("%02d", sec)
                if frac > 0 then
                    rep = rep .. tostring(frac):gsub("0(.-)0*$","%1")
                end
            end
            if value.zone then
                if value.zone >= 0 then
                    rep = rep .. '+' .. string.format("%02d:00", value.zone)
                elseif value.zone < 0 then
                    rep = rep .. '-' .. string.format("%02d:00", -value.zone)
                end
            end
            return '{"type":"datetime","value":"' .. rep .. '"}'
        end
        
        -- Check if it's an array (sequential numeric keys)
        local is_array = true
        local max_key = 0
        for k, v in pairs(value) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                is_array = false
                break
            end
            if k > max_key then
                max_key = k
            end
        end
        
        if is_array and max_key > 0 then
            -- It's an array
            local parts = {}
            for i = 1, max_key do
                table.insert(parts, encode_json(value[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            -- It's an object
            local parts = {}
            local keys = {}
            for k, v in pairs(value) do
                table.insert(keys, k)
            end
            table.sort(keys)
            
            for _, k in ipairs(keys) do
                local v = value[k]
                table.insert(parts, encode_json(tostring(k)) .. ":" .. encode_json(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        error("Unsupported type: " .. t)
    end
end

-- Main decoder function
local function main()
    -- Read TOML from stdin
    local toml_data = ""
    while true do
        local line = io.read("*line")
        if not line then
            break
        end
        toml_data = toml_data .. line .. "\n"
    end
    
    -- Parse TOML
    local result, error_msg = TOML.parse(toml_data)
    
    if not result then
        -- Parsing failed, output error to stderr and exit with non-zero code
        io.stderr:write("Error parsing TOML: " .. tostring(error_msg) .. "\n")
        os.exit(1)
    end
    
    -- Output JSON to stdout
    local json_output = encode_json(result)
    io.write(json_output .. "\n")
    os.exit(0)
end

-- Run the decoder
main()
