describe("key validation (v1.0.0)", function()
	setup(function()
		TOML = require "toml"
	end)

	it("bare keys - basic", function()
		local obj = TOML.parse[=[
key = "value"
bare_key = "value"
bare-key = "value"
1234 = "value"]=]
		local sol = {
			key = "value",
			bare_key = "value",
			["bare-key"] = "value",
			[1234] = "value"
		}
		assert.same(sol, obj)
	end)

	it("bare keys - numeric only", function()
		local obj = TOML.parse[=[
123 = "numeric key"
0 = "zero"]=]
		local sol = {
			[123] = "numeric key",
			[0] = "zero"
		}
		assert.same(sol, obj)
	end)

	it("quoted keys - basic strings", function()
		local obj = TOML.parse[=[
"127.0.0.1" = "value"
"character encoding" = "value"
"ʎǝʞ" = "value"]=]
		local sol = {
			["127.0.0.1"] = "value",
			["character encoding"] = "value",
			["ʎǝʞ"] = "value"
		}
		assert.same(sol, obj)
	end)

	it("quoted keys - literal strings", function()
		local obj = TOML.parse[=[
'key2' = "value"
'quoted "value"' = "value"]=]
		local sol = {
			key2 = "value",
			['quoted "value"'] = "value"
		}
		assert.same(sol, obj)
	end)

	it("empty quoted keys", function()
		-- In v1.0.0, redefining keys is invalid, even empty ones
		local obj, err = TOML.parse[=[
"" = "blank"
'' = 'blank2']=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("dotted keys - basic", function()
		local obj = TOML.parse[=[
name = "Orange"
physical.color = "orange"
physical.shape = "round"
site."google.com" = true]=]
		local sol = {
			name = "Orange",
			physical = {
				color = "orange",
				shape = "round"
			},
			site = {
				["google.com"] = true
			}
		}
		assert.same(sol, obj)
	end)

	it("dotted keys - whitespace handling", function()
		local obj = TOML.parse[=[
fruit.name = "banana"
fruit. color = "yellow"
fruit . flavor = "banana"]=]
		local sol = {
			fruit = {
				name = "banana",
				color = "yellow",
				flavor = "banana"
			}
		}
		assert.same(sol, obj)
	end)

	it("dotted keys - mixed quoted and bare", function()
		-- In v1.0.0, bare and quoted keys are equivalent, so this is key redefinition
		local obj, err = TOML.parse[=[
a.b = 1
"a"."b" = 2
'a'.'b' = 3]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("dotted keys - complex", function()
		local obj = TOML.parse[=[
fruit.apple.smooth = true
fruit.orange = 2
fruit."red apple".sweet = true]=]
		local sol = {
			fruit = {
				apple = {
					smooth = true
				},
				orange = 2,
				["red apple"] = {
					sweet = true
				}
			}
		}
		assert.same(sol, obj)
	end)

	it("floating point keys", function()
		local obj = TOML.parse[=[
3.14159 = "pi"]=]
		-- This creates nested structure as per spec
		local sol = {
			[3] = {
				[14159] = "pi"
			}
		}
		assert.same(sol, obj)
	end)

	it("invalid bare key characters", function()
		-- These should fail (excluding "." since it creates valid dotted keys)
		local invalid_chars = {"$", "!", "@", "#", "%", "^", "&", "*", "(", ")", "+", "=", 
		                       "[", "]", "{", "}", "|", "\\", ":", ";", "'", '"', 
		                       "<", ">", ",", "?", "/", "`", "~", " "}
		
		for _, char in ipairs(invalid_chars) do
			local toml_str = "key" .. char .. "name = 'value'"
			local obj, err = TOML.parse(toml_str)
			assert.same(nil, obj, "Should fail for character: " .. char)
			assert.same('string', type(err), "Should have error for character: " .. char)
		end
		
		-- Test that dot creates valid dotted keys (not an error)
		local obj, err = TOML.parse('key.name = "value"')
		assert.same(nil, err)  -- Should succeed
		assert.same('table', type(obj))
		assert.same({key = {name = "value"}}, obj)
	end)

	it("empty key error", function()
		local obj, err = TOML.parse[=[
= "no key name"]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("duplicate key error", function()
		local obj, err = TOML.parse[=[
name = "Tom"
name = "Pradyun"]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("bare vs quoted key equivalence", function()
		local obj, err = TOML.parse[=[
spelling = "favorite"
"spelling" = "favourite"]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("table vs value conflict", function()
		local obj, err = TOML.parse[=[
fruit.apple = 1
fruit.apple.smooth = true]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("unicode keys", function()
		local obj = TOML.parse[=[
"κόσμος" = "world"
"🍎" = "apple"
"测试" = "test"]=]
		local sol = {
			["κόσμος"] = "world",
			["🍎"] = "apple",
			["测试"] = "test"
		}
		assert.same(sol, obj)
	end)
end) 