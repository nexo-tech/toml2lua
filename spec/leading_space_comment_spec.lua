describe("leading space before comment", function()
	setup(function()
		TOML = require "toml"
	end)

	it("should parse TOML with leading spaces before comments", function()
		local toml_string = [[
[data.good] # This comment is good
somedata = 0
# This comment is also good

[data.bad]
    # This comment is bad]]

		local result, err = TOML.parse(toml_string)
		
		assert.is_nil(err)
		assert.is_not_nil(result)
		assert.are.equal(0, result.data.good.somedata)
		assert.is_not_nil(result.data.bad)
	end)

	it("should handle various whitespace patterns before comments", function()
		local toml_string = [[
[test]
value = 1
 # single space before comment
  # two spaces before comment
	# tab before comment
    # four spaces before comment]]

		local result, err = TOML.parse(toml_string)
		
		assert.is_nil(err)
		assert.is_not_nil(result)
		assert.are.equal(1, result.test.value)
	end)

	it("should distinguish between comments and hash in key names", function()
		local toml_string = [[
[test]
"key#with#hash" = "value"
# This is a comment
 # This is also a comment with leading space]]

		local result, err = TOML.parse(toml_string)
		
		assert.is_nil(err)
		assert.is_not_nil(result)
		assert.are.equal("value", result.test["key#with#hash"])
	end)

	it("should handle mixed whitespace and comments in complex structures", function()
		local toml_string = '[section1]\n' ..
		                   'key1 = "value1"\n' ..
		                   '    # Comment with leading spaces\n' ..
		                   '\n' ..
		                   '[section2] # Inline comment after section\n' ..
		                   'key2 = "value2"\n' ..
		                   ' # Another comment with single leading space\n' ..
		                   '\n' ..
		                   '[[array_of_tables]]\n' ..
		                   'name = "first"\n' ..
		                   '  # Comment in array of tables\n' ..
		                   '\n' ..
		                   '[[array_of_tables]]\n' ..
		                   'name = "second"\n' ..
		                   '\t# Comment with tab'

		local result, err = TOML.parse(toml_string)
		
		assert.is_nil(err)
		assert.is_not_nil(result)
		assert.are.equal("value1", result.section1.key1)
		assert.are.equal("value2", result.section2.key2)
		assert.are.equal(2, #result.array_of_tables)
		assert.are.equal("first", result.array_of_tables[1].name)
		assert.are.equal("second", result.array_of_tables[2].name)
	end)
end)