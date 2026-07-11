--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it setup
-- luacheck: ignore 143

describe("Serializer", function()
  local serialize
  local deserialize

  setup(function()
    serialize = rgcw.serializer.Serialize
    deserialize = rgcw.serializer.Deserialize
  end)

  --[[
    Round-trip a value and assert the result is deep-equal to the input.

    @param {any} value
  ]]--
  local function RoundTrip(value)
    local encoded = serialize(value)
    local decoded, err = deserialize(encoded)

    assert.is_nil(err)
    assert.same(value, decoded)
  end

  it("round-trips scalar values", function()
    RoundTrip(true)
    RoundTrip(false)
    RoundTrip(0)
    RoundTrip(-1)
    RoundTrip(42.5)
    RoundTrip(2 ^ 40)
    RoundTrip("")
    RoundTrip("hello")
  end)

  it("round-trips nil", function()
    -- assert.same(nil, x) passes for any falsy x, so check the success
    -- discriminator explicitly: Serialize(nil) is "z" and decoding it must
    -- yield nil without an error
    assert.equal("z", serialize(nil))

    local decoded, err = deserialize("z")

    assert.is_nil(decoded)
    assert.is_nil(err)
  end)

  it("round-trips adversarial strings", function()
    RoundTrip("contains:colon")
    RoundTrip("contains|pipe")
    RoundTrip("embedded s3:abc tag")
    RoundTrip("line\nbreak\ttab")
    RoundTrip(string.char(0, 1, 127, 255))
    RoundTrip(string.rep("x", 10000))
  end)

  it("round-trips nested tables with mixed keys", function()
    RoundTrip({})
    RoundTrip({ 1, 2, 3 })
    RoundTrip({
      name = "profile",
      [42] = { worstCase = true, value = 20 },
      nested = {
        frames = {
          CW_TargetCooldownWatchBar = { posX = 10.5, posY = -20, point = "CENTER" }
        }
      }
    })
  end)

  it("raises on unserializable values", function()
    assert.has_error(function() serialize(function() end) end)
  end)

  it("returns nil plus an error for malformed input instead of raising", function()
    local malformedInputs = {
      "",
      "x",             -- unknown type tag
      "s10:abc",       -- string shorter than its declared length
      "n3:abc",        -- number tag with non-numeric payload
      "nx:1",          -- non-digit length
      "t1:",           -- table header without its pair
      "t1:zz",         -- nil table key
      "zz",            -- trailing data after a complete value
      "s3:abcz"        -- trailing data after a complete string
    }

    for _, input in ipairs(malformedInputs) do
      local decoded
      local err

      assert.has_no.errors(function()
        decoded, err = deserialize(input)
      end)
      assert.is_nil(decoded)
      assert.is_string(err)
    end

    assert.is_nil(deserialize(nil))
    assert.is_nil(deserialize(42))
  end)

  it("rejects input nested beyond the depth limit without raising", function()
    -- 70 levels of table-with-one-pair, key "k", innermost value nil
    local bomb = string.rep("t1:s1:k", 70) .. "z"
    local decoded, err = deserialize(bomb)

    assert.is_nil(decoded)
    assert.equal("maximum nesting depth exceeded", err)
  end)

  it("never uses loadstring or load", function()
    local file = assert(io.open("code/Serializer.lua", "r"))
    local source = file:read("*a")
    file:close()

    -- match call sites only - the module comments legitimately mention
    -- loadstring when explaining why it is not used
    assert.is_nil(string.match(source, "loadstring%s*%("))
    -- %f[%w] guards against matching the load inside identifiers like payload
    assert.is_nil(string.match(source, "%f[%w]load%s*%("))
  end)
end)
