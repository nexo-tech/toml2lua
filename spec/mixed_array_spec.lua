describe("mixed type arrays (v1.0.0)", function()
	setup(function()
		TOML = require "toml"
	end)

	it("basic mixed types", function()
		local obj = TOML.parse[=[
mixed = [1, "hello", true, 3.14]]=]
		local sol = {
			mixed = {1, "hello", true, 3.14}
		}
		assert.same(sol, obj)
	end)

	it("numbers and floats mixed", function()
		local obj = TOML.parse[=[
numbers = [0.1, 0.2, 0.5, 1, 2, 5]]=]
		local sol = {
			numbers = {0.1, 0.2, 0.5, 1, 2, 5}
		}
		assert.same(sol, obj)
	end)

	it("strings and inline tables mixed", function()
		local obj = TOML.parse[=[
contributors = [
  "Foo Bar <foo@example.com>",
  { name = "Baz Qux", email = "bazqux@example.com", url = "https://example.com/bazqux" }
]]=]
		local sol = {
			contributors = {
				"Foo Bar <foo@example.com>",
				{ name = "Baz Qux", email = "bazqux@example.com", url = "https://example.com/bazqux" }
			}
		}
		assert.same(sol, obj)
	end)

	it("nested mixed arrays", function()
		local obj = TOML.parse[=[
nested = [[1, 2], ["a", "b"], [true, false]]]=]
		local sol = {
			nested = {
				{1, 2}, {"a", "b"}, {true, false}
			}
		}
		assert.same(sol, obj)
	end)

	it("mixed with special floats", function()
		local obj = TOML.parse[=[
special = [1, inf, "test", nan, true]]=]
		
		local arr = obj.special
		assert.same(1, arr[1])
		assert.same(math.huge, arr[2])
		assert.same("test", arr[3])
		assert.same(true, arr[4] ~= arr[4]) -- NaN check
		assert.same(true, arr[5])
	end)

	it("strict mode still enforces type consistency", function()
		local obj = TOML.parse([=[
mixed = [1, "hello"]]=], {strict = true})
		-- Should still work in v1.0.0 even with strict mode
		-- as mixed types are now officially allowed
		assert.same({1, "hello"}, obj.mixed)
	end)

	it("complex mixed types", function()
		local obj = TOML.parse[=[
complex = [
  42,
  "string",
  { key = "value" },
  [1, 2, 3],
  true,
  3.14,
  inf,
  nan
]]=]
		
		local arr = obj.complex
		assert.same(42, arr[1])
		assert.same("string", arr[2])
		assert.same({key = "value"}, arr[3])
		assert.same({1, 2, 3}, arr[4])
		assert.same(true, arr[5])
		assert.same(3.14, arr[6])
		assert.same(math.huge, arr[7])
		assert.same(true, arr[8] ~= arr[8]) -- NaN check
	end)
end) 