--!strict
-- Motion: the only place UI tweens are made. Every tween uses Theme.Motion (calm, weighted, no bounce) and is
-- interruptible: a new tween on the same instance cancels the previous one, so fast hovers never fight.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)

export type Speed = "Fast" | "Base" | "Slow"

local Motion = {}

local running: { [Instance]: Tween } = {}

function Motion.Info(speed: Speed?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): TweenInfo
	local m = Theme.Motion
	return TweenInfo.new((m :: any)[speed or "Base"], style or m.Style, direction or m.Direction)
end

-- Tweens props on instance at a named speed; returns the tween (already playing).
function Motion.To(instance: Instance, props: { [string]: any }, speed: Speed?, style: Enum.EasingStyle?): Tween
	local previous = running[instance]
	if previous then
		previous:Cancel()
	end
	local tween = TweenService:Create(instance, Motion.Info(speed, style), props)
	running[instance] = tween
	tween.Completed:Once(function()
		if running[instance] == tween then
			running[instance] = nil
		end
	end)
	tween:Play()
	return tween
end

-- Sets props immediately and cancels any running tween on the instance.
function Motion.Set(instance: Instance, props: { [string]: any })
	local previous = running[instance]
	if previous then
		previous:Cancel()
		running[instance] = nil
	end
	for key, value in props do
		(instance :: any)[key] = value
	end
end

return Motion
