defmodule Fleetbattlex.Physics do
	def apply_velocity(position, accelleration, dt) do
		movement = scale_vector(accelleration, dt)
		add_vectors(position, movement)
	end

	defp scale_vector({x,y}, scale), do: {x * scale, y * scale}

	defp add_vectors({x,y}, {x2,y2}), do: {x + x2, y + y2}
end
