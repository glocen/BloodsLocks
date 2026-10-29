--!strict
-- Ledger: one participant's score book, and standings across books. Pure data and math, no services; ScoreService
-- owns the books and LogicTestService tests this module directly.
--   Every gain is an entry (source, amount, phase, sequence number, optional detail and event key).
--   An event key can only pay once: a replayed event (a repeated request, a re-fired death) is refused.
--   A keyed entry can be revoked (a pledge overwritten by someone else): its amount leaves the total.
--   Standings: higher total first; on a tie, whoever reached their total first (the sequence number of the last entry
--   still counted, so a revoke moves it back); then the lower participant id, so the order is always the same.

local Ledger = {}

export type Entry = {
	Source: string,
	Amount: number,
	Seq: number, -- global order of gains (ScoreService's counter); stable even within one simulation step
	Phase: number, -- 0 before the first phase
	Detail: string?,
	Key: string?,
}

export type Book = {
	Total: number,
	Entries: { Entry },
	Keys: { [string]: true }, -- every key ever paid (a revoked key stays used)
}

function Ledger.new(): Book
	return { Total = 0, Entries = {}, Keys = {} }
end

-- Adds an entry. False when the amount isn't positive or its key already paid.
function Ledger.Add(book: Book, entry: Entry): boolean
	if entry.Amount <= 0 then
		return false
	end
	local key = entry.Key
	if key then
		if book.Keys[key] then
			return false
		end
		book.Keys[key] = true
	end
	table.insert(book.Entries, entry)
	book.Total += entry.Amount
	return true
end

-- Removes the entry paid under `key`. Returns the amount taken back (0 if there was none).
function Ledger.Revoke(book: Book, key: string): number
	for i, entry in book.Entries do
		if entry.Key == key then
			table.remove(book.Entries, i)
			book.Total -= entry.Amount
			return entry.Amount
		end
	end
	return 0
end

-- When the book reached its current total: the sequence number of its last counted entry (0 when empty).
function Ledger.ReachedSeq(book: Book): number
	local last = book.Entries[#book.Entries]
	return if last then last.Seq else 0
end

-- Totals per source (for commendations, debugging and the results screen).
function Ledger.BySource(book: Book): { [string]: number }
	local sums = {}
	for _, entry in book.Entries do
		sums[entry.Source] = (sums[entry.Source] or 0) + entry.Amount
	end
	return sums
end

-- The ids in standing order. `books` maps id -> book; ids without a book count as an empty book.
function Ledger.Rank(books: { [number]: Book }, ids: { number }): { number }
	local order = table.clone(ids)
	local empty = Ledger.new()
	table.sort(order, function(a, b)
		local ba, bb = books[a] or empty, books[b] or empty
		if ba.Total ~= bb.Total then
			return ba.Total > bb.Total
		end
		local ra, rb = Ledger.ReachedSeq(ba), Ledger.ReachedSeq(bb)
		if ra ~= rb then
			return ra < rb
		end
		return a < b
	end)
	return order
end

return Ledger
