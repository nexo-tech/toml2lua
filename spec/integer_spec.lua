describe("integer parsing", function()
	setup(function()
		TOML = require "toml"
	end)

	it("integer", function()
		local obj = TOML.parse[=[
answer = 42
neganswer = -42
posanswer = +42
underscore = 1_000]=]
		local sol = {
			answer = 42,
			neganswer = -42,
			posanswer = 42,
			underscore = 1000,
		}
		assert.same(sol, obj)
	end)

	it("long", function()
		local obj = TOML.parse[=[
answer = 9223372036854775807
neganswer = -9223372036854775808]=]
		local sol = {
			answer = 9223372036854775807,
			neganswer = -9223372036854775807-1 --> not using -9223372036854775808 because of a lua 5.3 parser bug
		}
		assert.same(sol, obj)
	end)

	it("zero", function()
		local obj, err = TOML.parse[=[
zero = 0]=]
		local sol = {
			zero = 0,
		}
		assert.same(sol, obj)
	end)

	it("leading zero error", function()
		local obj, err = TOML.parse[=[
answer = 042
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("base numbers", function()
		local obj = TOML.parse[=[
hex = 0xFF
oct = 0o777  
bin = 0b1010]=]
		local sol = {
			hex = 255,
			oct = 511,  -- 0o777 = 7*64 + 7*8 + 7*1 = 448 + 56 + 7 = 511
			bin = 10,
		}
		assert.same(sol, obj)
	end)
end)
