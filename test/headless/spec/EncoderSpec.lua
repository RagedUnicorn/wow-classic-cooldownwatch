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

describe("Encoder", function()
  local encode
  local decode

  setup(function()
    encode = rgcw.encoder.Encode
    decode = rgcw.encoder.Decode
  end)

  it("round-trips arbitrary byte strings", function()
    local inputs = {
      "",
      "hello",
      "s5:helloT", -- serializer output shape
      string.char(0, 1, 61, 127, 255), -- includes the base64 pad byte "="
      string.rep("payload", 500)
    }

    for _, input in ipairs(inputs) do
      local decoded, err = decode(encode(input))

      assert.is_nil(err)
      assert.equal(input, decoded)
    end
  end)

  it("produces paste-safe output without the WoW escape character", function()
    local encoded = encode(string.char(0, 124, 255) .. "some|piped|payload")

    assert.is_nil(string.find(encoded, "|", 1, true))
    assert.is_not_nil(string.match(encoded, "^[%w+/=]+$"))
  end)

  it("rejects non-string and empty input", function()
    local decoded, err = decode(nil)
    assert.is_nil(decoded)
    assert.equal("input", err)

    decoded, err = decode("")
    assert.is_nil(decoded)
    assert.equal("input", err)
  end)

  it("rejects malformed base64", function()
    local decoded, err = decode("@@@@")
    assert.is_nil(decoded)
    assert.equal("base64", err)

    -- length not a multiple of 4
    decoded, err = decode("abc")
    assert.is_nil(decoded)
    assert.equal("base64", err)

    -- padding in a non-final quartet
    decoded, err = decode("QQ==QQ==")
    assert.is_nil(decoded)
    assert.equal("base64", err)
  end)

  it("rejects input too short to carry the checksum header", function()
    -- valid base64 decoding to a single byte, less than the 4-byte header
    local decoded, err = decode("QQ==")

    assert.is_nil(decoded)
    assert.equal("truncated", err)
  end)

  it("detects a corrupted character via the checksum", function()
    local encoded = encode("a profile payload that gets corrupted in transit")
    local corruptIndex = 8
    local original = string.sub(encoded, corruptIndex, corruptIndex)
    local replacement = original == "A" and "B" or "A"
    local corrupted = string.sub(encoded, 1, corruptIndex - 1)
      .. replacement
      .. string.sub(encoded, corruptIndex + 1)

    local decoded, err = decode(corrupted)

    assert.is_nil(decoded)
    assert.equal("checksum", err)
  end)

  it("detects a truncated paste via the checksum", function()
    local encoded = encode("a profile payload that gets cut off mid paste")
    -- drop the last quartet so the base64 framing stays valid
    local truncated = string.sub(encoded, 1, #encoded - 4)

    local decoded, err = decode(truncated)

    assert.is_nil(decoded)
    assert.equal("checksum", err)
  end)
end)
