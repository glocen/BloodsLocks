--!strict
-- LogicTestService (Studio only): checks of the game's rule math with no playtest input needed: culls, rewards, rule
-- definitions, the world contract. It complements the movement/combat self-test (SelfTestController). Cases live in
-- the Cases child module; expected values come from the definitions wherever they can.
-- Run during a playtest, Server context:  game.ServerStorage.BL_Debug:Invoke("LogicTests")

local RunService = game:GetService("RunService")

local DebugService = require(script.Parent.DebugService)
local Cases = require(script.Cases)

export type Tester = {
	Check: (name: string, ok: boolean, detail: string?) -> (),
	Equal: (name: string, got: any, want: any) -> (),
}

local LogicTestService = {}

function LogicTestService.Run(): string
	local lines: { string } = {}
	local passed, failed = 0, 0
	for _, case in Cases do
		local function record(ok: boolean, name: string, detail: string?)
			if ok then
				passed += 1
			else
				failed += 1
			end
			table.insert(lines, `{if ok then "PASS" else "FAIL"}  {case.Name} · {name}{if detail then ` ({detail})` else ""}`)
		end
		local tester: Tester = {
			Check = function(name, ok, detail)
				record(ok, name, detail)
			end,
			Equal = function(name, got, want)
				record(got == want, name, `got {tostring(got)}, want {tostring(want)}`)
			end,
		}
		local ok, err = pcall(case.Run, tester)
		if not ok then
			record(false, "errored", tostring(err))
		end
	end
	local verdict = if failed == 0 then "PASSED" else "FAILED"
	table.insert(lines, 1, `LOGIC TESTS {verdict}: {passed} passed, {failed} failed`)
	return table.concat(lines, "\n")
end

function LogicTestService.Init()
	if RunService:IsStudio() then
		DebugService.Register("LogicTests", LogicTestService.Run)
	end
end

return LogicTestService
