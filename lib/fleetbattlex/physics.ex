defmodule Fleetbattlex.Physics do
	def apply_velocity(position, velocity, dt) do
		movement = scale_vector(velocity, dt)
		sum_vectors(position, movement)
	end

	def apply_accelleration(velocity, accelleration, dt) do
		accelleration_during_period = scale_vector(accelleration, dt)
		sum_vectors(velocity, accelleration_during_period)
	end

	def scale_vector({x,y}, scale), do: {x * scale, y * scale}

	def sum_vectors(vectors) when is_list(vectors) do
		vectors |> Enum.reduce({0,0}, &sum_vectors/2)
	end

	def sum_vectors({x,y}, {x2,y2}), do: {x + x2, y + y2}

end
