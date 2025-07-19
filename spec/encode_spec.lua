describe("encoding", function()
	setup(function()
		TOML = require "toml"
	end)

	it("array", function()
		local obj = TOML.encode{ a = { "foo","bar" } }
		local sol = "a = [\n\"foo\",\n\"bar\",\n]"
		assert.same(sol, obj)
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
