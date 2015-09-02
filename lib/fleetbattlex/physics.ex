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

	# def calculate_gravitational_field(massives, target_mass, location) do
	# 	G = 9.8
	# 	massives |> Enum.map(fn (massive = %Massive{mass: mass, position: position}) -> G*mass*target_mass/())
	# end

	def calculate_gravitational_field(%{mass: mass1, position: position1}, %{mass: mass2, position: position2}) do
		g = 10
		position_of_2_relative_to_1 = subtract_vector(position2,position1)
		distance = vector_length(position_of_2_relative_to_1)
		force_on_2_due_to_one = position_of_2_relative_to_1 |> scale_vector((-1 * g * mass1 * mass2) / :math.pow(distance,3))
		force_on_2_due_to_one
	end


	defp subtract_vector({x1,y1},{x2,y2}), do: {x2-x1, y2-y1}

	defp vector_length({x,y}), do: :math.sqrt(x*x + y*y)
end
