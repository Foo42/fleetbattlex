defmodule Fleetbattlex.Massive do
	alias Fleetbattlex.Physics
	alias __MODULE__

	defstruct mass: 1, position: {0,0}, velocity: {0,0}

	def progress_for_time(massive = %Massive{}, time, _forces \\ []) do
		massive |> apply_velocity(time) 
	end

	def apply_velocity(massive = %Massive{velocity: velocity, position: position}, time) do
		new_position = position |> Physics.apply_velocity(velocity, time)
		%{massive | position: new_position}
	end
end
