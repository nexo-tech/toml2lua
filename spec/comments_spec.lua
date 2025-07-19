describe("comments", function()
	setup(function()
		TOML = require "toml"
	end)

	it("everywhere", function()
		local obj = TOML.parse[=[
# Top comment.
  # Top comment.
# Top comment.

# [no-extraneous-groups-please]

[group] # Comment
answer = 42 # Comment
# no-extraneous-keys-please = 999
# Inbetween comment.
more = [ # Comment
  # What about multiple # comments?
  # Can you handle it?
  #
          # Evil.
# Evil.
  42, 42, # Comments within arrays are fun.
  # What about multiple # comments?
  # Can you handle it?
  #
          # Evil.
# Evil.
# ] Did I fool you?
] # Hopefully not.]=]
		local sol = {
			group = {
				answer = 42,
				more = {42, 42},
			}
		}
		assert.same(sol, obj)
	end)

	it("comment at end of file without newline (issue #27)", function()
		local obj = TOML.parse('[default]\ntest="test"\nnewTest="new test"\n#')
		local sol = {
			default = {
				test = "test",
				newTest = "new test",
			}
		}
		assert.same(sol, obj)
	end)

	it("various comment endings", function()
		-- Test comment at end with newline (should work)
		local obj1 = TOML.parse('[section]\nkey="value"\n#\n')
		local sol1 = { section = { key = "value" } }
		assert.same(sol1, obj1)
		
		-- Test comment at end without newline (should work)
		local obj2 = TOML.parse('[section]\nkey="value"\n#')
		local sol2 = { section = { key = "value" } }
		assert.same(sol2, obj2)
		
		-- Test comment with text at end without newline (should work)
		local obj3 = TOML.parse('[section]\nkey="value"\n# some comment text')
		local sol3 = { section = { key = "value" } }
		assert.same(sol3, obj3)
	end)
end)
