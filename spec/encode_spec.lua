describe("encoding", function()
	setup(function()
		TOML = require "toml"
	end)

	it("array", function()
		local obj = TOML.encode{ a = { "foo","bar" } }
		local sol = "a = [\n\"foo\",\n\"bar\",\n]"
		assert.same(sol, obj)
	end)

	-- Test for GitHub issue #18: Strings in arrays are not encoded correctly
	it("string array round-trip (issue #18)", function()
		local original_data = { field1 = { "str1", "str2", "I am a string" } }
		local encoded_data = TOML.encode(original_data)
		
		-- Verify encoding produces quoted strings
		assert.match('"str1"', encoded_data)
		assert.match('"str2"', encoded_data)
		assert.match('"I am a string"', encoded_data)
		
		-- Verify round-trip works
		local loaded_data = TOML.parse(encoded_data)
		assert.same(original_data, loaded_data)
	end)

	it("string arrays with special characters", function()
		local original_data = { 
			special = { "hello\nworld", 'quotes"here', "tabs\there", "backslash\\path" }
		}
		local encoded_data = TOML.encode(original_data)
		local loaded_data = TOML.parse(encoded_data)
		assert.same(original_data, loaded_data)
	end)

	it("mixed string and number arrays should fail parsing", function()
		-- This should encode but fail to parse due to type mismatch
		local data = { mixed = { "string", 42 } }
		local encoded = TOML.encode(data)
		local result, err = TOML.parse(encoded)
		assert.same(nil, result)
		assert.same('string', type(err))
	end)

	it("array of arrays with mixed integer and float", function()
		local obj = TOML.encode{ particle_color_graph = { { 1, 1, 1, 0.3 }, { 0, 0, 0, 0 } } }
		local sol = "particle_color_graph = [[1.0, 1.0, 1.0, 0.3], [0.0, 0.0, 0.0, 0.0]]"
		assert.same(sol, obj)
	end)

	it("array of arrays with all integers", function()
		local obj = TOML.encode{ coords = { { 1, 2, 3 }, { 4, 5, 6 } } }
		local sol = "coords = [[1, 2, 3], [4, 5, 6]]"
		assert.same(sol, obj)
	end)

	it("array of hash tables should still use table array syntax", function()
		local obj = TOML.encode{ people = { { name = "John", age = 30 }, { name = "Jane", age = 25 } } }
		local sol = "[[people]]\nname = \"John\"\nage = 30\n[[people]]\nname = \"Jane\"\nage = 25"
		assert.same(sol, obj)
	end)
end)
