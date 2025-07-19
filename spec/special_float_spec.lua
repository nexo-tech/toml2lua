describe("special float values", function()
	setup(function()
		TOML = require "toml"
	end)

	it("positive infinity", function()
		local obj = TOML.parse[=[
inf1 = inf
inf2 = +inf]=]
		local sol = {
			inf1 = math.huge,
			inf2 = math.huge,
		}
		assert.same(sol, obj)
		assert.same("number", type(obj.inf1))
		assert.same("number", type(obj.inf2))
		assert.same(true, obj.inf1 == math.huge)
		assert.same(true, obj.inf2 == math.huge)
	end)

	it("negative infinity", function()
		local obj = TOML.parse[=[
neginf = -inf]=]
		local sol = {
			neginf = -math.huge,
		}
		assert.same(sol, obj)
		assert.same("number", type(obj.neginf))
		assert.same(true, obj.neginf == -math.huge)
	end)

	it("not a number (nan)", function()
		local obj = TOML.parse[=[
nan1 = nan
nan2 = +nan
nan3 = -nan]=]
		
		assert.same("number", type(obj.nan1))
		assert.same("number", type(obj.nan2))
		assert.same("number", type(obj.nan3))
		
		-- NaN is not equal to itself
		assert.same(true, obj.nan1 ~= obj.nan1)
		assert.same(true, obj.nan2 ~= obj.nan2)
		assert.same(true, obj.nan3 ~= obj.nan3)
		
		-- Test NaN identification
		assert.same(true, tostring(obj.nan1):match("nan") ~= nil)
		assert.same(true, tostring(obj.nan2):match("nan") ~= nil)
		assert.same(true, tostring(obj.nan3):match("nan") ~= nil)
	end)

	it("mixed with regular floats", function()
		local obj = TOML.parse[=[
regular = 3.14
infinity = inf
negative_infinity = -inf
not_a_number = nan]=]
		
		assert.same(3.14, obj.regular)
		assert.same(math.huge, obj.infinity)
		assert.same(-math.huge, obj.negative_infinity)
		assert.same(true, obj.not_a_number ~= obj.not_a_number) -- NaN check
	end)

	it("in arrays", function()
		local obj = TOML.parse[=[
special_floats = [inf, -inf, nan, 1.0, 2.5]]=]
		
		local arr = obj.special_floats
		assert.same(math.huge, arr[1])
		assert.same(-math.huge, arr[2])
		assert.same(true, arr[3] ~= arr[3]) -- NaN check
		assert.same(1.0, arr[4])
		assert.same(2.5, arr[5])
	end)

	it("case sensitivity", function()
		-- These should all fail as TOML is case-sensitive
		local obj, err = TOML.parse[=[
bad_inf = Inf]=]
		assert.same(nil, obj)
		assert.same('string', type(err))

		local obj2, err2 = TOML.parse[=[
bad_nan = NaN]=]
		assert.same(nil, obj2)
		assert.same('string', type(err2))
	end)
end) 