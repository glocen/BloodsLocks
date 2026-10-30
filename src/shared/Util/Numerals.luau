--!strict
-- Numerals: Roman numerals for on-screen text ("Phase II"). Our Garamond fuses "II" into one glyph with a bar over it
-- (it reads as "Ī"), so the letters are kept apart with a zero-width non-joiner: it draws nothing and only stops the
-- ligature. Use Roman() for every numeral a player reads.

local ZWNJ = "\u{200C}"
local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }

local Numerals = {}

function Numerals.Roman(n: number): string
	local plain = ROMAN[n]
	if not plain then
		return tostring(n)
	end
	return table.concat(string.split(plain, ""), ZWNJ)
end

return Numerals
