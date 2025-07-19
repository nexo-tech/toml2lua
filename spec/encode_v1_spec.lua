describe("TOML.encode v1.0.0 compatibility", function()
	setup(function()
		TOML = require "toml"
	end)

	it("encodes special float values", function()
		local data = {
			positive_inf = math.huge,
			negative_inf = -math.huge,
			not_a_number = 0/0
		}
		
		local toml_str = TOML.encode(data)
		
		-- Verify inf and nan are encoded correctly
		assert.same(true, toml_str:match("positive_inf = inf") ~= nil)
		assert.same(true, toml_str:match("negative_inf = %-inf") ~= nil)
		-- NaN may be encoded as -nan or nan depending on Lua implementation
		assert.same(true, toml_str:match("not_a_number = .-nan") ~= nil)
	end)

	it("round-trip compatibility", function()
		local original = {
			string_val = "hello",
			integer_val = 42,
			float_val = 3.14,
			bool_val = true,
			inf_val = math.huge,
			array_val = {1, 2, 3},
			mixed_array = {1, "hello", true},
			table_val = {
				nested = "value"
			}
		}
		
		local encoded = TOML.encode(original)
		local decoded = TOML.parse(encoded)
		
		-- Most values should round-trip exactly
		assert.same(original.string_val, decoded.string_val)
		assert.same(original.integer_val, decoded.integer_val)
		assert.same(original.float_val, decoded.float_val)
		assert.same(original.bool_val, decoded.bool_val)
		assert.same(original.inf_val, decoded.inf_val)
		assert.same(original.array_val, decoded.array_val)
		assert.same(original.mixed_array, decoded.mixed_array)
		assert.same(original.table_val, decoded.table_val)
	end)

	it("encodes mixed-type arrays correctly", function()
		local data = {
			mixed = {1, "hello", true, 3.14, math.huge}
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		assert.same(data.mixed, decoded.mixed)
	end)

	it("encodes keys properly", function()
		local data = {
			bare_key = "value1",
			["quoted key"] = "value2",
			[""] = "empty key",
			[123] = "numeric key"
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		assert.same(data, decoded)
	end)

	it("encodes unicode strings", function()
		local data = {
			unicode = "Hello 世界 🌍",
			greek = "κόσμος",
			emoji = "🚀🌟"
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		assert.same(data, decoded)
	end)

	it("encodes escape sequences properly", function()
		local data = {
			with_newline = "line1\nline2",
			with_tab = "tab\there",
			with_quote = 'quote"here',
			with_backslash = "back\\slash"
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		assert.same(data, decoded)
	end)

	it("encodes nested tables", function()
		local data = {
			level1 = {
				level2 = {
					level3 = "deep value",
					number = 42
				},
				sibling = "value"
			}
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		assert.same(data, decoded)
	end)

	it("encodes array of tables", function()
		local data = {
			products = {
				{name = "Hammer", sku = 738594937},
				{},  -- empty table
				{name = "Nail", sku = 284758393, color = "gray"}
			}
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		assert.same(data, decoded)
	end)

	it("handles complex structures", function()
		local data = {
			title = "TOML Example",
			owner = {
				name = "Tom Preston-Werner",
				dob = TOML.datefy({year = 1979, month = 5, day = 27, hour = 7, min = 32, sec = 0, zone = -8})
			},
			database = {
				server = "192.168.1.1",
				ports = {8001, 8001, 8002},
				connection_max = 5000,
				enabled = true
			},
			servers = {
				{
					name = "alpha",
					ip = "10.0.0.1",
					dc = "eqdc10"
				},
				{
					name = "beta",
					ip = "10.0.0.2",
					dc = "eqdc10"
				}
			}
		}
		
		local toml_str = TOML.encode(data)
		local decoded = TOML.parse(toml_str)
		
		-- Check key components
		assert.same(data.title, decoded.title)
		assert.same(data.owner.name, decoded.owner.name)
		assert.same(data.database.server, decoded.database.server)
		assert.same(data.database.ports, decoded.database.ports)
		assert.same(data.servers[1].name, decoded.servers[1].name)
		assert.same(data.servers[2].ip, decoded.servers[2].ip)
	end)

	it("version string compatibility", function()
		-- Verify that the version is set to v1.0.0
		assert.same("1.0.0", TOML.version)
	end)
end) 