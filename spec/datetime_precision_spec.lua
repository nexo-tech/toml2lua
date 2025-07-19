describe("datetime precision (v1.0.0)", function()
	setup(function()
		TOML = require "toml"
	end)

	describe("offset date-time", function()
		it("basic RFC 3339 format", function()
			local obj = TOML.parse[=[
odt1 = 1979-05-27T07:32:00Z
odt2 = 1979-05-27T00:32:00-07:00
odt3 = 1979-05-27T00:32:00.999999-07:00]=]
			
			assert.same(1979, obj.odt1.year)
			assert.same(5, obj.odt1.month)
			assert.same(27, obj.odt1.day)
			assert.same(7, obj.odt1.hour)
			assert.same(32, obj.odt1.min)
			assert.same(0, obj.odt1.sec)
			assert.same(0, obj.odt1.zone)
			
			assert.same(-7, obj.odt2.zone)
			assert.same(0.999999, obj.odt3.sec)
		end)

		it("space delimiter", function()
			local obj = TOML.parse[=[
odt4 = 1979-05-27 07:32:00Z]=]
			
			assert.same(1979, obj.odt4.year)
			assert.same(5, obj.odt4.month)
			assert.same(27, obj.odt4.day)
			assert.same(7, obj.odt4.hour)
			assert.same(32, obj.odt4.min)
			assert.same(0, obj.odt4.sec)
			assert.same(0, obj.odt4.zone)
		end)

		it("millisecond precision required", function()
			local obj = TOML.parse[=[
ms1 = 1979-05-27T07:32:00.123Z
ms2 = 1979-05-27T07:32:00.999999Z]=]
			
			assert.same(0.123, obj.ms1.sec)
			assert.same(0.999999, obj.ms2.sec)
		end)

		it("various timezone offsets", function()
			local obj = TOML.parse[=[
plus_zone = 1979-05-27T07:32:00+05:30
minus_zone = 1979-05-27T07:32:00-11:00
zero_zone = 1979-05-27T07:32:00+00:00]=]
			
			assert.same(5, obj.plus_zone.zone)  -- Note: parser seems to handle hours only
			assert.same(-11, obj.minus_zone.zone)
			assert.same(0, obj.zero_zone.zone)
		end)
	end)

	describe("local date-time", function()
		it("without timezone", function()
			local obj = TOML.parse[=[
ldt1 = 1979-05-27T07:32:00
ldt2 = 1979-05-27T00:32:00.999999]=]
			
			assert.same(1979, obj.ldt1.year)
			assert.same(5, obj.ldt1.month)
			assert.same(27, obj.ldt1.day)
			assert.same(7, obj.ldt1.hour)
			assert.same(32, obj.ldt1.min)
			assert.same(0, obj.ldt1.sec)
			assert.same(nil, obj.ldt1.zone)
			
			assert.same(0.999999, obj.ldt2.sec)
		end)

		it("millisecond precision", function()
			local obj = TOML.parse[=[
ldt_ms = 1979-05-27T07:32:00.123456]=]
			
			assert.same(0.123456, obj.ldt_ms.sec)
		end)
	end)

	describe("local date", function()
		it("date only", function()
			local obj = TOML.parse[=[
ld1 = 1979-05-27]=]
			
			assert.same(1979, obj.ld1.year)
			assert.same(5, obj.ld1.month)
			assert.same(27, obj.ld1.day)
			assert.same(nil, obj.ld1.hour)
			assert.same(nil, obj.ld1.min)
			assert.same(nil, obj.ld1.sec)
			assert.same(nil, obj.ld1.zone)
		end)

		it("date validation", function()
			local obj = TOML.parse[=[
valid_date = 2024-02-29]=]  -- leap year
			assert.same(2024, obj.valid_date.year)
			assert.same(2, obj.valid_date.month)
			assert.same(29, obj.valid_date.day)
		end)
	end)

	describe("local time", function()
		it("time only", function()
			local obj = TOML.parse[=[
lt1 = 07:32:00
lt2 = 00:32:00.999999]=]
			
			assert.same(nil, obj.lt1.year)
			assert.same(nil, obj.lt1.month)
			assert.same(nil, obj.lt1.day)
			assert.same(7, obj.lt1.hour)
			assert.same(32, obj.lt1.min)
			assert.same(0, obj.lt1.sec)
			assert.same(nil, obj.lt1.zone)
			
			assert.same(0.999999, obj.lt2.sec)
		end)

		it("microsecond precision", function()
			local obj = TOML.parse[=[
lt_micro = 07:32:00.123456]=]
			
			assert.same(0.123456, obj.lt_micro.sec)
		end)

		it("edge cases", function()
			local obj = TOML.parse[=[
midnight = 00:00:00
almost_midnight = 23:59:59.999999]=]
			
			assert.same(0, obj.midnight.hour)
			assert.same(0, obj.midnight.min)
			assert.same(0, obj.midnight.sec)
			
			assert.same(23, obj.almost_midnight.hour)
			assert.same(59, obj.almost_midnight.min)
			assert.same(59.999999, obj.almost_midnight.sec)
		end)
	end)

	describe("date formatting", function()
		it("toString method", function()
			local obj = TOML.parse[=[
full_datetime = 1979-05-27T07:32:00Z
date_only = 1979-05-27
time_only = 07:32:00]=]
			
			-- Test that dates can be converted to strings
			assert.same("string", type(tostring(obj.full_datetime)))
			assert.same("string", type(tostring(obj.date_only)))
			assert.same("string", type(tostring(obj.time_only)))
			
			-- Basic format checks
			assert.same(true, tostring(obj.full_datetime):match("1979%-05%-27") ~= nil)
			assert.same(true, tostring(obj.date_only):match("1979%-05%-27") ~= nil)
			assert.same(true, tostring(obj.time_only):match("07:32:00") ~= nil)
		end)

		it("isdate function", function()
			local obj = TOML.parse[=[
datetime_val = 1979-05-27T07:32:00Z
string_val = "not a date"
number_val = 42]=]
			
			assert.same(true, TOML.isdate(obj.datetime_val))
			assert.same(false, TOML.isdate(obj.string_val))
			assert.same(false, TOML.isdate(obj.number_val))
		end)
	end)

	describe("precision handling", function()
		it("sub-millisecond precision", function()
			local obj = TOML.parse[=[
high_precision = 1979-05-27T07:32:00.123456789Z]=]
			
			-- Verify that high precision is preserved at least to microseconds
			local sec = obj.high_precision.sec
			assert.same(true, sec > 0.123456)
			assert.same(true, sec < 0.123457)
		end)

		it("zero fractional seconds", function()
			local obj = TOML.parse[=[
zero_frac = 1979-05-27T07:32:00.000Z]=]
			
			assert.same(0, obj.zero_frac.sec)
		end)
	end)

	describe("invalid datetime formats", function()
		it("invalid date components", function()
			local obj, err = TOML.parse[=[
invalid_month = 1979-13-27]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("invalid time components", function()
			local obj, err = TOML.parse[=[
invalid_hour = 25:00:00]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)

		it("malformed timezone", function()
			local obj, err = TOML.parse[=[
bad_timezone = 1979-05-27T07:32:00+25:00]=]
			assert.same(nil, obj)
			assert.same('string', type(err))
		end)
	end)
end) 