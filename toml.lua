local TOML = {
	-- denotes the current supported TOML version
	version = "1.0.0",

	-- sets whether the parser should follow the TOML spec strictly
	-- currently, no errors are thrown for the following rules if strictness is turned off:
	--   tables having mixed keys
	--   redefining a table
	--   redefining a key within a table
	strict = true,
}

local date_metatable = {
	__tostring = function( t )
		local rep = ''
		if t.year then
			rep = rep .. string.format("%04d-%02d-%02d", t.year, t.month, t.day)
		end
		if t.hour then
			if t.year then
				rep = rep .. ' '
			end
			rep = rep .. string.format("%02d:%02d:", t.hour, t.min)
			local sec, frac = math.modf( t.sec )
			rep = rep .. string.format("%02d", sec)
			if frac > 0 then
				rep = rep .. tostring(frac):gsub("0(.-)0*$","%1")
			end
		end
		if t.zone then
			if t.zone >= 0 then
				rep = rep .. '+' .. string.format("%02d:00", t.zone)
			elseif t.zone < 0 then
				rep = rep .. '-' .. string.format("%02d:00", -t.zone)
			end
		end
		return rep
	end,
}

local setmetatable, getmetatable = setmetatable, getmetatable

TOML.datefy = function( tab )
	-- Validate date/time components
	if tab.year and (tab.year < 0 or tab.year > 9999) then
		return nil, "Invalid year"
	end
	if tab.month and (tab.month < 1 or tab.month > 12) then
		return nil, "Invalid month"
	end
	if tab.day and (tab.day < 1 or tab.day > 31) then
		return nil, "Invalid day"
	end
	if tab.hour and (tab.hour < 0 or tab.hour > 23) then
		return nil, "Invalid hour"
	end
	if tab.min and (tab.min < 0 or tab.min > 59) then
		return nil, "Invalid minute"
	end
	if tab.sec and (tab.sec < 0 or tab.sec > 60) then  -- Allow leap seconds
		return nil, "Invalid second"
	end
	if tab.zone and (tab.zone < -23 or tab.zone > 23) then
		return nil, "Invalid timezone"
	end
	
	-- Additional validation for day based on month/year
	if tab.year and tab.month and tab.day then
		local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
		
		-- Check for leap year
		if tab.month == 2 and ((tab.year % 4 == 0 and tab.year % 100 ~= 0) or (tab.year % 400 == 0)) then
			days_in_month[2] = 29
		end
		
		if tab.day > days_in_month[tab.month] then
			return nil, "Invalid day for month"
		end
	end
	
	return setmetatable(tab, date_metatable)
end

TOML.isdate = function( tab )
	return getmetatable( tab ) == date_metatable
end

-- converts TOML data into a lua table
TOML.multistep_parser = function (options)
	options = options or {}
	local strict = (options.strict ~= nil and options.strict or TOML.strict)
	local toml = ''

	-- the output table
	local out = {}
	local ERR = {}

	-- the current table to write to
	local obj = out

	-- stores text data
	local buffer = ""

	-- the current location within the string to parse
	local cursor = 1

	-- remember that the last chunk was already read
	local stream_ended = false

	local nl_count = 1

	local function result_or_error()
		if #ERR > 0 then return nil, ERR[1] end
		return out
	end

	-- produce a parsing error message
	-- the error contains the line number of the current position
	local function err(message, strictOnly)
		if not strictOnly or (strictOnly and strict) then
			local line = 1
			local c = 0
			local msg = "At TOML line " .. nl_count .. ': ' .. message .. "."
			if not ERR[msg] then
				ERR[1+#ERR] = msg
				ERR[msg] = true
			end
		end
	end

	-- read n characters (at least) or chunk terminator (nil)
	local function getNewData(n)
		while not stream_ended do
			if cursor + (n or 0) < #toml then break end
			local new_data = coroutine.yield(result_or_error())
			if new_data == nil then
				stream_ended = true
				break
			end
			toml = toml:sub(cursor)
			cursor = 1
			toml = toml .. new_data
		end
	end

	-- TODO : use 1-based indexing ?
	-- returns the next n characters from the current position
	local function getData( a, b )
		getNewData(b)
		a = a or 0
		b = b or (toml:len() - cursor)
		return toml:sub( cursor + a, cursor + b )
	end

	-- returns the next n characters from the current position
	local function char(n)
		n = n or 0
		return getData(n, n)
	end

	-- count how many new lines are in the next n chars
	local function count_source_line(n)
		local count = 0
		for _ in getData(0, n-1):gmatch('\n') do
			count = count + 1
		end
		return count
	end

	-- function to check if current position is at a newline (LF or CRLF)
	local function isNewline()
		if char() == "\10" then  -- LF
			return true
		elseif char() == "\13" and char(1) == "\10" then  -- CRLF
			return true
		end
		return false
	end

	-- moves the current position forward n (default: 1) characters
	local function step(n)
		n = n or 1
		nl_count = nl_count + count_source_line(n)
		cursor = cursor + n
	end

	-- prevent infinite loops by checking whether the cursor is
	-- at the end of the document or not
	local function bounds()
		if cursor <= toml:len() then return true end
		getNewData(1)
		return cursor <= toml:len()
	end

	-- Check if we are at end of the data
	local function dataEnd()
		return cursor >= toml:len()
	end

	-- Match official TOML definition of whitespace
	local function matchWs(n)
		n = n or 0
		return getData(n,n):match("[\009\032]")
	end

	-- Match the official TOML definition of newline
	local function matchnl(n)
		n = n or 0
		local c = getData(n,n)
		if c == '\10' then return '\10' end
		return getData(n,n+1):match("^\13\10")
	end

	-- move forward until the next non-whitespace character
	local function skipWhitespace()
		while(matchWs()) do
			step()
		end
	end

	-- remove the (Lua) whitespace at the beginning and end of a string
	local function trim(str)
		return str:gsub("^%s*(.-)%s*$", "%1")
	end

	-- divide a string into a table around a delimiter
	local function split(str, delim)
		if str == "" then return {} end
		local result = {}
		local append = delim
		if delim:match("%%") then
			append = delim:gsub("%%", "")
		end
		for match in (str .. append):gmatch("(.-)" .. delim) do
			table.insert(result, match)
		end
		return result
	end

	local function parseString()
		local quoteType = char() -- should be single or double quote

		-- this is a multiline string if the next 2 characters match
		local multiline = (char(1) == char(2) and char(1) == char())

		-- buffer to hold the string
		local str = ""

		-- skip the quotes
		step(multiline and 3 or 1)

		local foundClosingQuote = false
		
		while(bounds()) do
			if multiline and matchnl() and str == "" then
				-- skip line break line at the beginning of multiline string
				if char() == "\13" and char(1) == "\10" then
					step(2)  -- skip CRLF
				else
					step()   -- skip LF
				end
			end

			-- keep going until we encounter the quote character again
			if char() == quoteType then
				if multiline then
					if char(1) == char(2) and char(1) == quoteType then
						step(3)
						foundClosingQuote = true
						break
					end
				else
					step()
					foundClosingQuote = true
					break
				end
			end

			if matchnl() and not multiline then
				err("Single-line string cannot contain line break")
			end

			-- if we're in a double-quoted string, watch for escape characters!
			if quoteType == '"' and char() == "\\" then
				if multiline and matchnl(1) then
					-- skip until first non-whitespace character
					step(1) -- go past the line break
					while(bounds()) do
						if not matchWs() and not matchnl() then
							break
						end
						if isNewline() then
							if char() == "\13" and char(1) == "\10" then
								step(2)  -- skip CRLF
							else
								step()   -- skip LF
							end
						else
							step()
						end
					end
				else
					-- all available escape characters
					local escape = {
						b = "\b",
						t = "\t",
						n = "\n",
						f = "\f",
						r = "\r",
						['"'] = '"',
						["\\"] = "\\",
					}
					-- utf function from http://stackoverflow.com/a/26071044
					-- converts \uXXX into actual unicode
					local function utf(char)
						local bytemarkers = {{0x7ff, 192}, {0xffff, 224}, {0x1fffff, 240}}
						if char < 128 then return string.char(char) end
						local charbytes = {}
						for bytes, vals in pairs(bytemarkers) do
							if char <= vals[1] then
								for b = bytes + 1, 2, -1 do
									local mod = char % 64
									char = (char - mod) / 64
									charbytes[b] = string.char(128 + mod)
								end
								charbytes[1] = string.char(vals[2] + char)
								break
							end
						end
						return table.concat(charbytes)
					end

					if escape[char(1)] then
						-- normal escape
						str = str .. escape[char(1)]
						step(2) -- go past backslash and the character
					elseif char(1) == "u" then
						-- utf-16
						step()
						local uni = char(1) .. char(2) .. char(3) .. char(4)
						step(5)
						uni = tonumber(uni, 16)
						if not uni then
							err("Unicode escape is not a Unicode scalar")
						elseif (uni >= 0 and uni <= 0xd7ff) and not (uni >= 0xe000 and uni <= 0x10ffff) then
							str = str .. utf(uni)
						else
							err("Unicode escape is not a Unicode scalar")
						end
					elseif char(1) == "U" then
						-- utf-32
						step()
						local uni = char(1) .. char(2) .. char(3) .. char(4) .. char(5) .. char(6) .. char(7) .. char(8)
						step(9)
						uni = tonumber(uni, 16)
						if (uni >= 0 and uni <= 0xd7ff) and not (uni >= 0xe000 and uni <= 0x10ffff) then
							str = str .. utf(uni)
						else
							err("Unicode escape is not a Unicode scalar")
						end
					else
						err("Invalid escape")
						step()
					end
				end
			else
				-- if we're not in a double-quoted string, just append it to our buffer raw and keep going
				str = str .. char()
				step()
			end
		end

		-- If we get here without finding the closing quote, it's an error
		if not foundClosingQuote then
			err("Unterminated string")
		end

		return {value = str, type = "string"}
	end

	local function matchDate()
		local year, month, day, n =
			getData(0, 10):match('^(%d%d%d%d)%-([0-1][0-9])%-([0-3][0-9])()')

		if not year then return nil end
		step(n-1)

		return year, month, day
	end

	local function matchTime()
		local hour, minute, second, n =
			getData(0, 19):match('^([0-2][0-9])%:([0-6][0-9])%:(%d+%.?%d*)()')

		if not hour then return nil end
		step(n-1)

		return hour, minute, second
	end

	local function matchTimezone()
		local eastwest, offset, zero, n =
			getData(0, 6):match('^([%+%-])([0-9][0-9])%:([0-9][0-9])()')

		if not eastwest then return nil end
		step(n-1)

		return eastwest .. offset
	end

	local function parseDate()

		local year, month, day = matchDate()
		if not year then err("Invalid date") end

		local hour, minute, second = '', '', '', ''

		local date_time_separator = false
		if char():match('[T ]') then
			step(1)
			date_time_separator = true
		end

		local n
		if date_time_separator then
			hour, minute, second, n = matchTime()
			if not hour then err("Invalid date") end
		end

		local zone
		if char():match('Z') then
			step(1)
			zone = 0
		else
			local timezone = matchTimezone()
			if timezone then
				zone = tonumber(timezone)
			end
		end

		local value = {
			year = tonumber(year),
			month = tonumber(month),
			day = tonumber(day),
			hour = tonumber(hour),
			min = tonumber(minute),
			sec = tonumber(second),
			zone = zone,
		}

		local e
		value, e = TOML.datefy(value)
		if not value then
			err(e)
		end

		return {
			type = "date",
			value = value,
		}
	end

	local function parseTime()
		local hour, minute, second, n = matchTime()
		if not hour then err("Invalid date") end

		local value = {
			hour = tonumber(hour),
			min = tonumber(minute),
			sec = tonumber(second),
		}

		local value, e = TOML.datefy(value)
		if not value then err(e) end

		return {
			type = "date",
			value = value,
		}
	end

	local function parseNumber()
		local num = ""
		local exp
		local date = false
		local dotfound = false
		local prev_underscore = false
		
		-- Support for hex, octal, and binary numbers
		local prefixes = { ["0x"] = 16, ["0o"] = 8, ["0b"] = 2 }
		local base = prefixes[char() .. char(1)]
		if base then
			step(2)
			local digits = ({ [2] = "[01]", [8] = "[0-7]", [16] = "%x" })[base]
			local prev_underscore_alt = false
			while(bounds()) do
				if char():match(digits) then
					num = num .. char()
					prev_underscore_alt = false
				elseif matchWs() or char() == "#" or matchnl() or char() == "," or char() == "]" or char() == "}" then
					break
				elseif char() == "_" then
					if prev_underscore_alt then
						err("Double underscore in number")
					end
					if num == "" then
						err("Underscore cannot be at beginning of number")
					end
					prev_underscore_alt = true
				else
					err("Invalid number")
				end
				step()
			end
			if prev_underscore_alt then
				err("Invalid underscore at end of number")
			end
			if num == "" then
				err("Invalid number")
			end
			return {value = tonumber(num, base), type = "integer"}
		end
		
		while(bounds()) do
			if char():match("[%+%-%.eE_0-9]") then
				if char():match'%.' then dotfound = true end
				if not exp then
					if char():lower() == "e" then
						-- as soon as we reach e or E, start appending to exponent buffer instead of
						-- number buffer
						exp = ""
					elseif char() ~= "_" then
						num = num .. char()
					end
				elseif char():match("[%+%-_0-9]") then
					if char() ~= "_" then
						exp = exp .. char()
					end
				else
					err("Invalid exponent")
				end
			elseif matchWs() or char() == "#" or matchnl() or char() == "," or char() == "]" or char() == "}" then
				break
			else
				err("Invalid number")
			end
			if char() == '_' and num:sub(#num) == '.' then
				err('Undescore after decimal point')
			end
			if char() == '_' and char(1) == '.' then
				err('Undescore before decimal point')
			end
			if char() == '_' and prev_underscore then
				err('Double underscore in number')
			end
			if char() == "_" then
				prev_underscore = true
			else
				prev_underscore = false
			end
			step()
		end

		if prev_underscore then
			err("Invalid undescore at end of number")
		end

		if date then
			return {value = num, type = "date"}
		end

		if num:match('^[%+%-]?0[0-9]') then
			err('Leading zero found in number')
		end
		if dotfound then
			if num:match('%.$') then
				err('No trailing zero found in float')
			end
		end

		local exp_val = exp and tonumber(exp) or 0
		local multiplier = 1
		if exp_val > 0 then
			multiplier = math.floor(10 ^ exp_val)
		elseif exp_val < 0 then
			multiplier = 10 ^ exp_val
		elseif exp_val == 0 then
			multiplier = 1
		end
		num = tonumber(num) * multiplier

		if exp_val < 0 or dotfound then
			return {value = num, type = "float"}
		end
		return {value = num, type = "integer"}
	end

	local parseArray, getValue
	
	function parseArray()
		step() -- skip [
		skipWhitespace()

		local arrayType
		local array = {}

		while(bounds()) do
			if char() == "]" then
				break
			elseif matchnl() then
				-- skip
				step()
				skipWhitespace()
			elseif char() == "#" then
				while(bounds() and not matchnl()) do
					step()
				end
			else
				-- get the next object in the array
				local v = getValue()
				if not v then break end

				-- v1.0.0 allows mixed types in arrays
				if arrayType == nil then
					arrayType = v.type
				elseif arrayType ~= v.type then
					-- Mixed types are allowed in v1.0.0, so just update arrayType to indicate mixed
					arrayType = "mixed"
				end

				array = array or {}
				table.insert(array, v.value)
				
				if char() == "," then
					step()
				end
				skipWhitespace()
			end
		end
		
		-- Check if we found the closing bracket
		if not bounds() or char() ~= "]" then
			err("Missing closing bracket in array")
		end
		step()

		return {value = array, type = "array"}
	end

	local function parseInlineTable()
		step() -- skip opening brace

		local buffer = ""
		local quoted = false
		local tbl = {}

		while bounds() do
			if char() == "}" then
				break
			elseif char() == "'" or char() == '"' then
				buffer = parseString().value
				quoted = true
				skipWhitespace()
			elseif char() == "=" then
				if not quoted then
					buffer = trim(buffer)
				end

				step() -- skip =
				skipWhitespace()

				if matchnl() then
					err("Newline in inline table")
				end

				local v = getValue().value
				tbl[buffer] = v

				skipWhitespace()

				if char() == "," then
					step()
					skipWhitespace()
					if matchnl() then
						err("Newline in inline table")
					end
				elseif matchnl() then
					err("Newline in inline table")
				end

				quoted = false
				buffer = ""
			else
				if quoted then
					if not matchWs() then
						err("Unexpected character after the key")
					end
				else
					if matchnl() then
						err("Newline in inline table")
					end
					buffer = buffer .. char()
				end
				step()
			end
		end
		
		-- Check if we found the closing brace
		if not bounds() or char() ~= "}" then
			err("Missing closing brace in inline table")
		end
		step() -- skip closing brace

		return {value = tbl, type = "array"}
	end

	local function parseBoolean()
		local v
		if getData(0, 3) == "true" then
			step(4)
			v = {value = true, type = "boolean"}
		elseif getData(0, 4) == "false" then
			step(5)
			v = {value = false, type = "boolean"}
		elseif getData(0, 2) == "inf" then
			step(3)
			v = {value = math.huge, type = "float"}
		elseif getData(0, 3) == "+inf" then
			step(4)
			v = {value = math.huge, type = "float"}
		elseif getData(0, 3) == "-inf" then
			step(4)
			v = {value = -math.huge, type = "float"}
		elseif getData(0, 2) == "nan" then
			step(3)
			v = {value = 0/0, type = "float"}
		elseif getData(0, 3) == "+nan" then
			step(4)
			v = {value = 0/0, type = "float"}
		elseif getData(0, 3) == "-nan" then
			step(4)
			v = {value = 0/0, type = "float"}
		else
			err("Invalid primitive")
		end

		skipWhitespace()
		if char() == "#" then
			while(bounds() and not matchnl()) do
				step()
			end
		end

		return v
	end

	-- figure out the type and get the next value in the document
	function getValue()
		if char() == '"' or char() == "'" then
			return parseString()
		elseif getData(0,5):match("^%d%d%d%d%-%d") then
			return parseDate()
		elseif getData(0,3):match("^%d%d%:%d") then
			return parseTime()
		elseif getData(0, 2) == "inf" or getData(0, 3) == "+inf" or getData(0, 3) == "-inf" or
		       getData(0, 2) == "nan" or getData(0, 3) == "+nan" or getData(0, 3) == "-nan" then
			return parseBoolean()  -- Special float values handled in parseBoolean
		elseif char():match("[%+%-0-9]") then
			return parseNumber()
		elseif char() == "[" then
			return parseArray()
		elseif char() == "{" then
			return parseInlineTable()
		else
			return parseBoolean()
		end
		-- date regex (for possible future support):
		-- %d%d%d%d%-[0-1][0-9]%-[0-3][0-9]T[0-2][0-9]%:[0-6][0-9]%:[0-6][0-9][Z%:%+%-%.0-9]*
	end

	local function parse()

		local function check_key()
			if buffer == "" then
				err("Empty key")
			end
			if buffer:match("[%s%c%%%(%)%*%+%.%?%[%]!\"#$&',/:;<=>@`\\^{|}~]") and not quotedKey then
				err('Invalid character in key')
			end
		end

		-- avoid double table definition
		local defined_table = setmetatable({},{__mode='kv'})

		-- keep track of container type i.e. table vs array
		local container_type = setmetatable({},{__mode='kv'})

		local function processKey(isLast, tableArray)
			if isLast and obj[buffer] and not tableArray and #obj[buffer] > 0 then
				err("Cannot redefine table", true)
			end

			-- set obj to the appropriate table so we can start
			-- filling it with values!
			if tableArray then
				-- push onto cache
				local current = obj[buffer]

				-- crete as needed + identify table vs array
				local isArray = false
				if current then
					isArray = (container_type[current] == 'array')
				else
					current = {}
					obj[buffer] = current
					if isLast then
						isArray = true
						container_type[current] = 'array'
					else
						isArray = false
						container_type[current] = 'hash'
					end
				end

				if isLast and not isArray then
						err('The selected key contains a table, not an array', true)
				end

				-- update current object
				if not isLast then obj = current end
				if isArray then
					if isLast then table.insert(current, {}) end
					obj = current[#current]
				end

			else
				local newObj = obj[buffer] or {}
				obj[buffer] = newObj
				if #newObj > 0 then
					if type(newObj) ~= 'table' then
						err('Duplicate field')
					else
						-- an array is already in progress for this key, so modify its
						-- last element, instead of the array itself
						obj = newObj[#newObj]
					end
				else
					obj = newObj
				end
			end
			if isLast then
				if defined_table[obj] then
					err('Duplicated table definition')
				end
				defined_table[obj] = true
			end
		end

		local function check_key()
			if buffer == "" then
				err("Empty key")
			end
			if buffer:match("[%s%c%%%(%)%*%+%.%?%[%]!\"#$&',/:;<=>@`\\^{|}~]") and not quotedKey then
				err('Invalid character in key')
			end
		end

		-- avoid double table definition
		local defined_table = setmetatable({},{__mode='kv'})

		-- keep track of container type i.e. table vs array
		local container_type = setmetatable({},{__mode='kv'})

		local function processKey(isLast, tableArray, quotedKey)
			if isLast and obj[buffer] and not tableArray and #obj[buffer] > 0 then
				err("Cannot redefine table", true)
			end

			-- set obj to the appropriate table so we can start
			-- filling it with values!
			if tableArray then
				-- push onto cache
				local current = obj[buffer]

				-- crete as needed + identify table vs array
				local isArray = false
				if current then
					isArray = (container_type[current] == 'array')
				else
					current = {}
					obj[buffer] = current
					if isLast then
						isArray = true
						container_type[current] = 'array'
					else
						isArray = false
						container_type[current] = 'hash'
					end
				end

				if isLast and not isArray then
						err('The selected key contains a table, not an array', true)
				end

				-- update current object
				if not isLast then obj = current end
				if isArray then
					if isLast then table.insert(current, {}) end
					obj = current[#current]
				end

			else
				local newObj = obj[buffer] or {}
				obj[buffer] = newObj
				if #newObj > 0 then
					if type(newObj) ~= 'table' then
						err('Duplicate field')
					else
						-- an array is already in progress for this key, so modify its
						-- last element, instead of the array itself
						obj = newObj[#newObj]
					end
				else
					obj = newObj
				end
			end
			if isLast then
				if defined_table[obj] then
					err('Duplicated table definition')
				end
				defined_table[obj] = true
			end
		end

		-- track whether the current key was quoted or not
		local quotedKey = false
		
		-- track dotted key parsing state
		local dottedKeyParts = {}
		local inDottedKey = false

		-- parse the document!
		while(bounds()) do
	
			-- skip comments and whitespace
			-- Only treat # as comment if we're not in the middle of parsing a key
			if char() == "#" and (buffer == "" or quotedKey) then
				while(bounds() and not matchnl()) do
					step()
				end
			end

			if matchnl() then
				if trim(buffer) ~= '' then
					err('Invalid key')
				end
				buffer = ""
				dottedKeyParts = {}
				inDottedKey = false
				step()
			elseif char() == "=" then
				step()
				skipWhitespace()
				
				-- Add current buffer to dotted key parts if we're in a dotted key
				if inDottedKey then
					if not quotedKey then
						buffer = trim(buffer)
					end
					if buffer ~= "" then
						table.insert(dottedKeyParts, buffer)
					end
				end

				-- Handle dotted keys vs regular keys
				if inDottedKey and #dottedKeyParts > 1 then
					-- This is a dotted key - create nested structure
					local currentObj = obj
					local conflictDetected = false
					
					for i = 1, #dottedKeyParts - 1 do
						local key = dottedKeyParts[i]
						if key:match("^[0-9]+$") then
							key = tonumber(key)
						end
						if not currentObj[key] then
							currentObj[key] = {}
						elseif type(currentObj[key]) ~= "table" then
							err('Cannot create table: key "' .. key .. '" already has a non-table value')
							conflictDetected = true
							break
						end
						currentObj = currentObj[key]
					end
					
					if not conflictDetected then
						local finalKey = dottedKeyParts[#dottedKeyParts]
						if finalKey:match("^[0-9]+$") then
							finalKey = tonumber(finalKey)
						end
						
						local v = getValue()
						if v then
							if currentObj[finalKey] ~= nil then
								err('Cannot redefine key "' .. finalKey .. '"', true)
							end
							currentObj[finalKey] = v.value
						end
					else
						-- Still need to consume the value even if there was a conflict
						getValue()
					end
				elseif not quotedKey and buffer:find("%.") then
					-- Handle simple dotted keys (backward compatibility)
					local keys = {}
					for key in buffer:gmatch("[^%.]+") do
						table.insert(keys, key)
					end
					
					-- Validate each key segment
					for _, key in ipairs(keys) do
						local tempBuffer = key
						if tempBuffer:match("[%s%c%%%(%)%*%+%.%?%[%]!\"#$&',/:;<=>@`\\^{|}~]") then
							err('Invalid character in key')
						end
					end
					
					-- Navigate/create the nested structure
					local currentObj = obj
					local conflictDetected = false
					for i = 1, #keys - 1 do
						local key = keys[i]
						if key:match("^[0-9]+$") then
							key = tonumber(key)
						end
						if not currentObj[key] then
							currentObj[key] = {}
						elseif type(currentObj[key]) ~= "table" then
							err('Cannot create table: key "' .. key .. '" already has a non-table value')
							conflictDetected = true
							break
						end
						currentObj = currentObj[key]
					end
					
					-- Set the final key only if no conflict was detected
					if not conflictDetected then
						local finalKey = keys[#keys]
						if finalKey:match("^[0-9]+$") then
							finalKey = tonumber(finalKey)
						end
						
						local v = getValue()
						if v then
							if currentObj[finalKey] ~= nil then
								err('Cannot redefine key "' .. finalKey .. '"', true)
							end
							currentObj[finalKey] = v.value
						end
					else
						-- Still need to consume the value even if there was a conflict
						getValue()
					end
				else
					-- Regular key handling
					if not quotedKey then 
						buffer = trim(buffer)
						check_key() 
					end

					if buffer:match("^[0-9]+$") and not quotedKey then
						buffer = tonumber(buffer)
					end

					if buffer == "" and not quotedKey then
						err("Empty key name")
					end
					local v = getValue()
					if v then
						-- if the key already exists in the current object, throw an error
						if obj[buffer] ~= nil then
							err('Cannot redefine key "' .. buffer .. '"', true)
						end
						obj[buffer] = v.value
					end
				end

				-- clear the buffer and reset dotted key state
				buffer = ""
				dottedKeyParts = {}
				inDottedKey = false
				quotedKey = false

				-- skip whitespace and comments
				skipWhitespace()
				if char() == "#" then
					while(bounds() and not matchnl()) do
						step()
					end
				end

				-- if there is anything left on this line after parsing a key and its value,
				-- throw an error
				if not dataEnd() and not matchnl() then
					err("Invalid primitive")
				end
			elseif char() == "[" then
				if trim(buffer) ~= '' then
					err("Invalid key")
				end

				buffer = ""
				step()
				local tableArray = false

				-- if there are two brackets in a row, it's a table array!
				if char() == "[" then
					tableArray = true
					step()
				end

				obj = out

				while(bounds()) do
					if char() == "]" then
						break
					elseif char() == '"' or char() == "'" then
						buffer = parseString().value
						quotedKey = true
					elseif char() == "." then
						step() -- skip period
						if not quotedKey then
							buffer = trim(buffer)
						end
						if not quotedKey then check_key() end
						processKey(false, tableArray, quotedKey)
						buffer = ""
					elseif char() == "[" then
						err('Invalid character in key')
						step()
					else
						buffer = buffer .. char()
						step()
					end
				end
				if tableArray then
					if char(1) ~= "]" then
						err("Mismatching brackets")
					else
						step() -- skip inside bracket
					end
				end
				step() -- skip outside bracket
				if not quotedKey then
					buffer = trim(buffer)
				end
				if not quotedKey then check_key() end
				processKey(true, tableArray, quotedKey)
				buffer = ""
				buffer = ""
				quotedKey = false
				skipWhitespace()
				if bounds() and (not char():match('#') and not matchnl()) then
					err("Something found on the same line of a table definition")
				end
			elseif char() == "." then
				-- Handle dot in dotted key
				if buffer == "" then
					err("Empty key segment before dot")
				end
				
				-- Add current buffer content to dotted key parts
				if not quotedKey then
					buffer = trim(buffer)
				end
				if buffer == "" then
					err("Empty key segment")
				end
				table.insert(dottedKeyParts, buffer)
				inDottedKey = true
				buffer = ""
				quotedKey = false
				step()
			elseif (char() == '"' or char() == "'") then
				-- quoted key
				buffer = parseString().value
				quotedKey = true

			else
				if not quotedKey then
					buffer = buffer .. (matchnl() and "" or char())
				end
				step()
			end
		end

		-- Check for incomplete line at end of file
		if trim(buffer) ~= '' then
			err('Invalid key')
		end

		return result_or_error()
	end

	local coparse = coroutine.wrap(parse)
	coparse()
	return coparse
end

TOML.parse = function(data, options)
	local cp = TOML.multistep_parser(options)
	cp(data)
	return cp()
end

TOML.encode = function(tbl)
	local toml = ""

	local cache = {}

	-- Helper function to encode keys properly according to TOML v1.0.0 spec
	local function encodeKey(key)
		local keyStr = tostring(key)
		
		-- Empty keys must be quoted
		if keyStr == "" then
			return '""'
		end
		
		-- Check if the key needs quoting (contains special characters)
		-- Bare keys may only contain ASCII letters, ASCII digits, underscores, and dashes (A-Za-z0-9_-)
		if keyStr:match("^[A-Za-z0-9_%-]+$") then
			return keyStr
		else
			-- Key needs to be quoted, escape quotes and backslashes
			local escapedKey = keyStr:gsub("\\", "\\\\"):gsub('"', '\\"')
			return '"' .. escapedKey .. '"'
		end
	end

	-- Helper function to encode dotted table names
	local function encodeDottedName(keyList)
		local encodedKeys = {}
		for i, key in ipairs(keyList) do
			table.insert(encodedKeys, encodeKey(key))
		end
		return table.concat(encodedKeys, ".")
	end

	-- Helper function to get sorted keys for consistent output order
	local function getSortedKeys(t)
		local keys = {}
		for k in pairs(t) do
			table.insert(keys, k)
		end
		-- Sort keys, handling mixed types gracefully
		table.sort(keys, function(a, b)
			local ta, tb = type(a), type(b)
			if ta == tb then
				return tostring(a) > tostring(b)  -- Reverse alphabetical order
			else
				return ta < tb  -- type names sorted alphabetically
			end
		end)
		return keys
	end

	local function parse(tbl)
		local keys = getSortedKeys(tbl)
		
		-- First pass: handle all non-table values
		for _, k in ipairs(keys) do
			local v = tbl[k]
			if type(v) == "boolean" then
				toml = toml .. encodeKey(k) .. " = " .. tostring(v) .. "\n"
			elseif type(v) == "number" then
				-- Handle special float values for v1.0.0 compatibility
				if v == math.huge then
					toml = toml .. encodeKey(k) .. " = inf\n"
				elseif v == -math.huge then
					toml = toml .. encodeKey(k) .. " = -inf\n"
				elseif v ~= v then  -- NaN check (NaN != NaN)
					toml = toml .. encodeKey(k) .. " = nan\n"
				else
					toml = toml .. encodeKey(k) .. " = " .. tostring(v) .. "\n"
				end
			elseif type(v) == "string" then
				local quote = '"'
				v = v:gsub("\\", "\\\\")

				-- if the string has any line breaks, make it multiline
				if v:match("^\n(.*)$") then
					quote = quote:rep(3)
					v = "\\n" .. v
				elseif v:match("\n") then
					quote = quote:rep(3)
				end

				v = v:gsub("\b", "\\b")
				v = v:gsub("\t", "\\t")
				v = v:gsub("\f", "\\f")
				v = v:gsub("\r", "\\r")
				v = v:gsub('"', '\\"')
				toml = toml .. encodeKey(k) .. " = " .. quote .. v .. quote .. "\n"
			elseif type(v) == "table" and getmetatable(v) == date_metatable then
				toml = toml .. encodeKey(k) .. " = " .. tostring(v) .. "\n"
			end
		end
		
		-- Second pass: handle simple array values (arrays of non-tables)
		for _, k in ipairs(keys) do
			local v = tbl[k]
			if type(v) == "table" and getmetatable(v) ~= date_metatable then
				-- Check if this is an array (all numeric keys)
				local isArray = true
				local isArrayOfHashTables = true
				for kk, vv in pairs(v) do
					if type(kk) ~= "number" then
						isArray = false
						break
					end
					if type(vv) ~= "table" then
						isArrayOfHashTables = false
					else
						-- Check if the inner table is a hash table (has non-numeric keys)
						local isHashTable = false
						local hasKeys = false
						for kkk, vvv in pairs(vv) do
							hasKeys = true
							if type(kkk) ~= "number" then
								isHashTable = true
								break
							end
						end
						-- Empty tables are considered hash tables for array of tables syntax
						if hasKeys and not isHashTable then
							isArrayOfHashTables = false
						end
					end
				end
				
				if isArray and not isArrayOfHashTables then
					-- Check if this is an array of arrays (all elements are arrays)
					local isArrayOfArrays = true
					for kk, vv in pairs(v) do
						if type(vv) ~= "table" then
							isArrayOfArrays = false
							break
						end
						-- Check if the inner table is also an array
						for kkk, vvv in pairs(vv) do
							if type(kkk) ~= "number" then
								isArrayOfArrays = false
								break
							end
						end
						if not isArrayOfArrays then break end
					end
					
					if isArrayOfArrays then
						-- This is an array of arrays, encode as nested arrays
						toml = toml .. encodeKey(k) .. " = ["
						local first_outer = true
						for kk, vv in pairs(v) do
							if not first_outer then
								toml = toml .. ", "
							end
							toml = toml .. "["
							local first_inner = true
							for kkk, vvv in pairs(vv) do
								if not first_inner then
									toml = toml .. ", "
								end
								if type(vvv) == "number" then
									-- Check if any number in any array is a float
									local hasFloat = false
									for _, arr in pairs(v) do
										for _, val in pairs(arr) do
											if type(val) == "number" and val ~= math.floor(val) then
												hasFloat = true
												break
											end
										end
										if hasFloat then break end
									end
									if hasFloat then
										toml = toml .. string.format("%.1f", vvv)
									else
										toml = toml .. tostring(vvv)
									end
								else
									toml = toml .. tostring(vvv)
								end
								first_inner = false
							end
							toml = toml .. "]"
							first_outer = false
						end
						toml = toml .. "]\n"
					else
						-- This is a simple array, use multi-line format
						toml = toml .. encodeKey(k) .. " = [\n"
						for kk, vv in pairs(v) do
							if type(vv) == "string" then
								local escaped_string = vv
								escaped_string = escaped_string:gsub("\\", "\\\\")
								escaped_string = escaped_string:gsub("\b", "\\b")
								escaped_string = escaped_string:gsub("\t", "\\t")
								escaped_string = escaped_string:gsub("\f", "\\f")
								escaped_string = escaped_string:gsub("\r", "\\r")
								escaped_string = escaped_string:gsub("\n", "\\n")
								escaped_string = escaped_string:gsub('"', '\\"')
								toml = toml .. '"' .. escaped_string .. '",\n'
							else
								toml = toml .. tostring(vv) .. ",\n"
							end
						end
						toml = toml .. "]\n"
					end
				end
			end
		end
		
		-- Third pass: handle hash table values and arrays of tables
		for _, k in ipairs(keys) do
			local v = tbl[k]
			if type(v) == "table" and getmetatable(v) ~= date_metatable then
				-- Check if this is an array (all numeric keys)
				local isArray = true
				local isArrayOfHashTables = true
				for kk, vv in pairs(v) do
					if type(kk) ~= "number" then
						isArray = false
						break
					end
					if type(vv) ~= "table" then
						isArrayOfHashTables = false
					else
						-- Check if the inner table is a hash table (has non-numeric keys)
						local isHashTable = false
						local hasKeys = false
						for kkk, vvv in pairs(vv) do
							hasKeys = true
							if type(kkk) ~= "number" then
								isHashTable = true
								break
							end
						end
						-- Empty tables are considered hash tables for array of tables syntax
						if hasKeys and not isHashTable then
							isArrayOfHashTables = false
						end
					end
				end
				
				if isArray and isArrayOfHashTables then
					-- This is an array of hash tables, use [[table]] syntax
					for kk, vv in pairs(v) do
						toml = toml .. "[[" .. encodeKey(k) .. "]]\n"
						if type(vv) == "table" then
							parse(vv)
						end
					end
				elseif not isArray then
				local array, arrayTable = true, true
				local first = {}
				local tableCopy = {}
				for kk, vv in pairs(v) do
					if type(kk) ~= "number" then array = false end
					if type(vv) ~= "table" then
						first[kk] = vv
						arrayTable = false
					else
						tableCopy[kk] = vv
					end
				end

				if array then
					if arrayTable then
						-- Check if inner tables are arrays (all numeric keys) or hash tables
						local innerTablesAreArrays = true
						for kk, vv in pairs(tableCopy) do
							for k3, v3 in pairs(vv) do
								if type(k3) ~= "number" then
									innerTablesAreArrays = false
									break
								end
							end
							if not innerTablesAreArrays then
								break
							end
						end
						
						if innerTablesAreArrays then
							-- This is an array of arrays, encode as nested array
							toml = toml .. encodeKey(k) .. " = ["
							
							-- Check if any element in any array is a float to determine formatting
							local hasFloat = false
							for kk, vv in pairs(tableCopy) do
								for k3, v3 in pairs(vv) do
									if type(v3) == "number" and v3 ~= math.floor(v3) then
										hasFloat = true
										break
									end
								end
								if hasFloat then break end
							end
							
							local first_element = true
							for kk, vv in pairs(tableCopy) do
								if not first_element then
									toml = toml .. ", "
								end
								toml = toml .. "["
								local first_inner = true
								
								for k3, v3 in pairs(vv) do
									if not first_inner then
										toml = toml .. ", "
									end
									if type(v3) == "string" then
										toml = toml .. '"' .. v3 .. '"'
									elseif type(v3) == "number" then
										if hasFloat then
											-- Format all numbers as floats for consistency
											toml = toml .. string.format("%.1f", v3)
										else
											toml = toml .. tostring(v3)
										end
									else
										toml = toml .. tostring(v3)
									end
									first_inner = false
								end
								toml = toml .. "]"
								first_element = false
							end
							toml = toml .. "]\n"
						else
							-- double bracket syntax go!
							table.insert(cache, k)
							for kk, vv in pairs(tableCopy) do
								toml = toml .. "[[" .. encodeDottedName(cache) .. "]]\n"
								local tableCopyInner = {}
								local firstInner = {}
								local sortedKeys = getSortedKeys(vv)
								for _, k3 in ipairs(sortedKeys) do
									local v3 = vv[k3]
									if type(v3) ~= "table" then
										firstInner[k3] = v3
									else
										tableCopyInner[k3] = v3
									end
								end
								parse(firstInner)
								parse(tableCopyInner)
							end
							table.remove(cache)
						end
					else
						-- plain ol boring array
						toml = toml .. encodeKey(k) .. " = [\n"
						local quote = '"'
						for kk, vv in pairs(first) do
							if type(vv) == "string" then
								local escaped_string = vv
								escaped_string = escaped_string:gsub("\\", "\\\\")
								escaped_string = escaped_string:gsub("\b", "\\b")
								escaped_string = escaped_string:gsub("\t", "\\t")
								escaped_string = escaped_string:gsub("\f", "\\f")
								escaped_string = escaped_string:gsub("\r", "\\r")
								escaped_string = escaped_string:gsub("\n", "\\n")
								escaped_string = escaped_string:gsub('"', '\\"')
								toml = toml .. quote .. escaped_string .. quote .. ",\n"
							else
								toml = toml .. tostring(vv) .. ",\n"
							end
						end
						toml = toml .. "]\n"
					end
				else
					-- just a key/value table, folks
					table.insert(cache, k)
					toml = toml .. "[" .. encodeDottedName(cache) .. "]\n"
					parse(first)
					parse(tableCopy)
					table.remove(cache)
				end
			end
		end
		end
	end
	
	parse(tbl)
	
	return toml:sub(1, -2)
end

return TOML

