defmodule Fleetbattlex.Physics do
	def apply_velocity(_position = {x,y}, _accelleration = {dx,dy}, dt) do
		{(x + dx * dt),(y + dy * dt)}
	end
end
