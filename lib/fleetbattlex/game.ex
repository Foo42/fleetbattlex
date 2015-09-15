defmodule Fleetbattlex.Game do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive
	alias Fleetbattlex.Physics

	def start_link() do
		Logger.info "in game start_link"
		GenServer.start_link(__MODULE__,%{pieces: [
			%Massive{velocity: {0,8}, position: {50,0}},
			%Massive{velocity: {0.0, 0.0}, position: {100,0}, mass: 25}
		], ships: Fleetbattlex.Ship.start_link(%Massive{velocity: {0,10}, position: {40,0}})})
	end

	def init(args) do
		seconds = 0.5
		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:ok, args}
	end

	def handle_info(:game_tick, state = %{pieces: pieces }) do
		Logger.info "tick"

		seconds = 0.1

		gravity_for_each = pieces |> Enum.map(&gravity_from_others(&1, pieces))
		Logger.info "gravity for each = #{inspect gravity_for_each}"
		pieces_with_gravity = Enum.zip(pieces,gravity_for_each)

		updated_pieces = pieces_with_gravity |> Enum.map(fn {piece, gravity} -> Massive.progress_for_time(piece, seconds, [gravity]) end)
		Logger.info "pieces = #{inspect updated_pieces}"

		positions = updated_pieces |> Enum.map(fn %{position: {x,y}} -> %{position: %{x: x, y: y}} end)
		Fleetbattlex.Endpoint.broadcast! "positions:updates", "update", %{positions: positions}

		
		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:noreply, %{state | pieces: updated_pieces}}
	end

	defp gravity_from_others(target = %{position: position, mass: mass}, others) do
		is_self = fn %{position: other_position} -> other_position == position end

		others 
			|> Enum.reject(is_self)
			|> Enum.map(&Physics.calculate_gravitational_field(target, &1))
			# |> Enum.map(fn {x,y} -> {-x,-y}end)
			|> Physics.sum_vectors
	end
end
