defmodule Fleetbattlex.Game do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive

	def start_link() do
		Logger.info "in game start_link"
		GenServer.start_link(__MODULE__,%{pieces: [%Massive{velocity: {0.1,0.1}}]})
	end

	def init(args) do
		seconds = 1
		:erlang.send_after(seconds * 1000, self(), :game_tick)
		{:ok, args}
	end

	def handle_info(:game_tick, state = %{pieces: pieces }) do
		Logger.info "tick"

		updated_pieces = pieces |> Enum.map(&(Massive.progress_for_time(&1, 1)))
		Logger.info "pieces = #{inspect updated_pieces}"

		positions = updated_pieces |> Enum.map(fn %{position: {x,y}} -> %{position: %{x: x, y: y}} end)
		Fleetbattlex.Endpoint.broadcast! "positions:updates", "update", %{positions: positions}

		seconds = 1
		:erlang.send_after(seconds * 1000, self(), :game_tick)
		{:noreply, %{state | pieces: updated_pieces}}
	end
end
