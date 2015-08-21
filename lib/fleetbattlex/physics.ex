defmodule Fleetbattlex.Physics do
	def apply_velocity(position, velocity, dt) do
		movement = scale_vector(velocity, dt)
		add_vectors(position, movement)
	end

	def apply_accelleration(velocity, accelleration, dt) do
		accelleration_during_period = scale_vector(accelleration, dt)
		add_vectors(velocity, accelleration_during_period)
	end

	defp scale_vector({x,y}, scale), do: {x * scale, y * scale}

	defp add_vectors({x,y}, {x2,y2}), do: {x + x2, y + y2}
end
