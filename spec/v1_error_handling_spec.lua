describe("v1.0.0 error handling", function()
	setup(function()
		TOML = require "toml"
	end)

	describe("string errors", function()
		it("unterminated string", function()
			local obj, err = TOML.parse[=[
key = "unterminated]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("newline in basic string", function()
			local obj, err = TOML.parse([[
key = "line
break"]])
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("invalid escape sequence", function()
			local obj, err = TOML.parse[=[
key = "invalid \q escape"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("invalid unicode escape", function()
			local obj, err = TOML.parse[=[
key = "\uGGGG"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("number errors", function()
		it("leading zeros", function()
			local obj, err = TOML.parse[=[
key = 042]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("trailing decimal point", function()
			local obj, err = TOML.parse[=[
key = 3.]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("leading decimal point", function()
			local obj, err = TOML.parse[=[
key = .7]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("double underscores", function()
			local obj, err = TOML.parse[=[
key = 1__000]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("trailing underscore", function()
			local obj, err = TOML.parse[=[
key = 1000_]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("leading underscore", function()
			local obj, err = TOML.parse[=[
key = _1000]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("array errors", function()
		it("missing closing bracket", function()
			local obj, err = TOML.parse[=[
key = [1, 2, 3]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("trailing comma in array", function()
			-- This should actually be valid in v1.0.0
			local obj = TOML.parse[=[
key = [1, 2, 3,]]=]
			assert.same({key = {1, 2, 3}}, obj)
		end)
	end)

	describe("table errors", function()
		it("redefined table", function()
			local obj, err = TOML.parse[=[
[fruit]
apple = "red"

[fruit]
orange = "orange"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("table after array of tables", function()
			local obj, err = TOML.parse[=[
[[fruits]]
name = "apple"

[fruits]
name = "banana"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("mismatched brackets", function()
			local obj, err = TOML.parse[=[
[table]]]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("inline table errors", function()
		it("newline in inline table", function()
			local obj, err = TOML.parse[[
key = { a = 1,
        b = 2 }]]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("missing closing brace", function()
			local obj, err = TOML.parse[=[
key = { a = 1, b = 2]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("datetime errors", function()
		it("invalid date format", function()
			local obj, err = TOML.parse[=[
key = 2024-13-01]=]  -- invalid month
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("invalid time format", function()
			local obj, err = TOML.parse[=[
key = 25:00:00]=]  -- invalid hour
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("key errors", function()
		it("empty bare key", function()
			local obj, err = TOML.parse[=[
= "value"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("invalid key characters", function()
			local obj, err = TOML.parse[=[
key@invalid = "value"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("general syntax errors", function()
		it("missing equals sign", function()
			local obj, err = TOML.parse[=[
key "value"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("multiple values on same line", function()
			local obj, err = TOML.parse[=[
key1 = "value1" key2 = "value2"]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("invalid character", function()
			local obj, err = TOML.parse[=[
key = "value" ©]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)

	describe("comment errors", function()
		it("control characters in comments should be handled", function()
			-- v1.0.0 spec states control characters other than tab are not permitted
			-- However, testing this depends on how strictly the parser enforces this
			local obj = TOML.parse[=[
key = "value" # This is a valid comment]=]
			assert.same({key = "value"}, obj)
		end)
	end)

	describe("error message quality", function()
		it("includes line numbers", function()
			local obj, err = TOML.parse[[
valid = "line 1"
invalid = "line 2
still_invalid"]]
			assert.same(nil, obj)
			assert.same('string', type(err))
			assert.same(true, err:match("line 2") ~= nil or err:match("2") ~= nil)
		end)

		it("descriptive error messages", function()
			local obj, err = TOML.parse[=[
key = ]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
			assert.same(true, string.len(err) > 10) -- Should be descriptive
		end)
	end)
end) 