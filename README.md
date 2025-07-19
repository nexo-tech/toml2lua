# toml.lua

Version: 3.0.0

Use [toml](https://github.com/toml-lang/toml) with lua!

The core parser is based on TOML 0.4.0 but for the time being, the
date parsing should be considered experimental.

The following features of TOML 0.5.0 are supported too (descriptions taken from
the TOML changelog):

- Add Local Date-Time.
- Add Local Date.
- Add Local Time.
- Allow space (instead of T) to separate date and time in Date-Time.

# Usage

    TOML = require "toml"
    TOML.parse(string)
    tomlOut = TOML.encode(table)

To process a file in multiple chunks:

    local parser = TOML.multistep_parser()
    parser(string_part_1)
    parser(string_part_2)
    -- ...
    local result = parser()

To enable more lua-friendly features (like mixed arrays):

    TOML.strict = false

or:

    TOML.parse(string, {strict = false})

or:

    local parser = TOML.multistep_parser{strict = false}

In case of error, nil plus an error message is returned.

# License

lua-toml is licensed under [MIT](https://opensource.org/licenses/MIT).

```
Copyright (c) 2017 Jonathan Stoler
Copyright (c) 2025 Oleg Pustovit and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## Fork Maintainer

This fork is maintained by [Oleg Pustovit](https://github.com/nexo-tech), building on the work of [Jon Stoler](https://github.com/jonstoler/lua-toml) and the original contributors.

## Contributions

Includes pull requests and contributions from:

- [Natanael Copa](https://github.com/ncopa) — fix encoding of plain ol borring arrays (issue [#12](https://github.com/jonstoler/lua-toml/issues/12))
- [Luka Vandervelden](https://github.com/Lukc) — Lua 5.1 marked as supported in the rockspec. (issue [#20](https://github.com/jonstoler/lua-toml/issues/20))
- [Ekaterina Vaartis](https://github.com/vaartis) - Don't replace / with \/, because the library can't decode that back
- Work on issues [#11](https://github.com/jonstoler/lua-toml/issues/11) [#17](https://github.com/jonstoler/lua-toml/issues/17) [#22](https://github.com/jonstoler/lua-toml/issues/22) (+ merged [#20](https://github.com/jonstoler/lua-toml/issues/20) by [@mattwidmann](https://github.com/mattwidmann) and [#18](https://github.com/jonstoler/lua-toml/issues/18) by [@OrenjiAkira](https://github.com/OrenjiAkira)) [#23](https://github.com/jonstoler/lua-toml/issues/23)
