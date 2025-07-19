describe("base number parsing", function()
	setup(function()
		TOML = require "toml"
	end)

	it("hexadecimal numbers", function()
		local obj = TOML.parse[=[
hex1 = 0xDEADBEEF
hex2 = 0xdeadbeef
hex3 = 0x0
hex4 = 0xFF
hex5 = 0xabcdef
hex6 = 0x123456789ABCDEF]=]
		local sol = {
			hex1 = 0xDEADBEEF,
			hex2 = 0xdeadbeef,
			hex3 = 0x0,
			hex4 = 0xFF,
			hex5 = 0xabcdef,
			hex6 = 0x123456789ABCDEF,
		}
		assert.same(sol, obj)
	end)

	it("octal numbers", function()
		local obj = TOML.parse[=[
oct1 = 0o777
oct2 = 0o644
oct3 = 0o0
oct4 = 0o755
oct5 = 0o123456701]=]
		local sol = {
			oct1 = tonumber("777", 8),
			oct2 = tonumber("644", 8),
			oct3 = 0,
			oct4 = tonumber("755", 8),
			oct5 = tonumber("123456701", 8),
		}
		assert.same(sol, obj)
	end)

	it("binary numbers", function()
		local obj = TOML.parse[=[
bin1 = 0b11010110
bin2 = 0b0
bin3 = 0b1
bin4 = 0b101010101010
bin5 = 0b11111111]=]
		local sol = {
			bin1 = tonumber("11010110", 2),
			bin2 = 0,
			bin3 = 1,
			bin4 = tonumber("101010101010", 2),
			bin5 = tonumber("11111111", 2),
		}
		assert.same(sol, obj)
	end)

	it("hex with underscores", function()
		local obj = TOML.parse[=[
hex_under1 = 0xDEAD_BEEF
hex_under2 = 0xde_ad_be_ef
hex_under3 = 0xFF_00_FF]=]
		local sol = {
			hex_under1 = 0xDEADBEEF,
			hex_under2 = 0xdeadbeef,
			hex_under3 = 0xFF00FF,
		}
		assert.same(sol, obj)
	end)

	it("octal with underscores", function()
		local obj = TOML.parse[=[
oct_under1 = 0o777_000
oct_under2 = 0o64_4
oct_under3 = 0o7_5_5]=]
		local sol = {
			oct_under1 = tonumber("777000", 8),
			oct_under2 = tonumber("644", 8),
			oct_under3 = tonumber("755", 8),
		}
		assert.same(sol, obj)
	end)

	it("binary with underscores", function()
		local obj = TOML.parse[=[
bin_under1 = 0b1101_0110
bin_under2 = 0b10_10_10_10
bin_under3 = 0b1111_1111_0000_0000]=]
		local sol = {
			bin_under1 = tonumber("11010110", 2),
			bin_under2 = tonumber("10101010", 2),
			bin_under3 = tonumber("1111111100000000", 2),
		}
		assert.same(sol, obj)
	end)

	it("invalid hex numbers", function()
		local obj, err = TOML.parse[=[
bad_hex = 0xGHIJ
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("invalid octal numbers", function()
		local obj, err = TOML.parse[=[
bad_oct = 0o89
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("invalid binary numbers", function()
		local obj, err = TOML.parse[=[
bad_bin = 0b234
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("empty hex number", function()
		local obj, err = TOML.parse[=[
empty_hex = 0x
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("empty octal number", function()
		local obj, err = TOML.parse[=[
empty_oct = 0o
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("empty binary number", function()
		local obj, err = TOML.parse[=[
empty_bin = 0b
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("underscore at beginning of number", function()
		local obj, err = TOML.parse[=[
bad_under = 0x_FF
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("underscore at end of number", function()
		local obj, err = TOML.parse[=[
bad_under = 0xFF_
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("double underscore in number", function()
		local obj, err = TOML.parse[=[
bad_under = 0xFF__00
]=]
		assert.same(nil, obj)
		assert.same('string', type(err))
	end)

	it("mixed case hex", function()
		local obj = TOML.parse[=[
mixed_case = 0xAbCdEf
]=]
		local sol = {
			mixed_case = 0xAbCdEf,
		}
		assert.same(sol, obj)
	end)

	it("large numbers", function()
		local obj = TOML.parse[=[
large_hex = 0xFFFFFFFFFFFFFFFF
large_oct = 0o1777777777777777777777
large_bin = 0b1111111111111111111111111111111111111111111111111111111111111111
]=]
		local sol = {
			large_hex = tonumber("FFFFFFFFFFFFFFFF", 16),
			large_oct = tonumber("1777777777777777777777", 8),
			large_bin = tonumber("1111111111111111111111111111111111111111111111111111111111111111", 2),
		}
		assert.same(sol, obj)
	end)
end) 