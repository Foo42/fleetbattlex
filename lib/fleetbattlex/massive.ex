defmodule Fleetbattlex.Massive do
	alias Fleetbattlex.Physics
	alias __MODULE__

	defstruct mass: 1, position: {0,0}, velocity: {0,0}

	def progress_for_time(massive = %Massive{}, time, forces \\ []) do
		massive |> apply_force(forces) |> apply_velocity(time) 
	end

	def apply_velocity(massive = %Massive{velocity: velocity, position: position}, time) do
		new_position = position |> Physics.apply_velocity(velocity, time)
		%{massive | position: new_position}
	end

	def apply_force(massive = %Massive{mass: mass, velocity: velocity}, forces) do
		new_velocity = forces |> Physics.sum_vectors |> Physics.scale_vector(1/mass) |> Physics.sum_vectors(velocity)
		%{massive | velocity: new_velocity}
	end
end
