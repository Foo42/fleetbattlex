defmodule Fleetbattlex.Game do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive
	alias Fleetbattlex.Physics
	alias Fleetbattlex.Ship

	def start_link() do
		Logger.info "in game start_link"
		GenServer.start_link(__MODULE__,%{pieces: [
			%Massive{velocity: {0,8}, position: {50,0}},
			%Massive{velocity: {0.0, 0.0}, position: {100,0}, mass: 25}
		], ships: [
			Ship.start_link(%Massive{velocity: {0,8}, position: {50,0}}),
			Ship.start_link(%Massive{velocity: {0.0, 0.0}, position: {100,0}, mass: 25})
		] |> Enum.map(fn {:ok, pid} -> pid end)})
	end

	def init(args) do
		seconds = 0.1
		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:ok, initialise_positions(args)}
	end

	def handle_info(:game_tick, state = %{ships: ships, last_positions: last_positions }) do
		Logger.info "tick"

		seconds = 0.1

		gravity_for_each = last_positions |> Enum.map(&gravity_from_others(&1, last_positions))
		Logger.info "gravity for each = #{inspect gravity_for_each}"
		ships_with_gravity = Enum.zip(ships,gravity_for_each)

		updated_posititions = ships_with_gravity |> Enum.map(fn {ship, gravity} -> Ship.progress_for_time(ship, seconds, [gravity]) end)
		Logger.info "updated_posititions = #{inspect updated_posititions}"

		position_update_message = updated_posititions |> Enum.map(fn %{position: {x,y}} -> %{position: %{x: x, y: y}} end)
		Fleetbattlex.Endpoint.broadcast! "positions:updates", "update", %{positions: position_update_message}

		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:noreply, %{state | last_positions: updated_posititions}}
	end

	defp gravity_from_others(target = %{position: position, mass: mass}, others) do
		is_self = fn %{position: other_position} -> other_position == position end

		others 
			|> Enum.reject(is_self)
			|> Enum.map(&Physics.calculate_gravitational_field(target, &1))
			|> Physics.sum_vectors
	end

	defp initialise_positions(state)do
		Logger.info "initialising positions for #{inspect state.ships}"
		positions = state.ships |> Enum.map(&Ship.current_position(&1))
		Dict.put(state,:last_positions, positions)
	end
end
