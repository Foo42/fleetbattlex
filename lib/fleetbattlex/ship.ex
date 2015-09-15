defmodule Fleetbattlex.Ship do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive

	def start_link(params = %Massive{}) do
		GenServer.start_link(__MODULE__,%{massive: params})
	end

	def init(args) do
		{:ok, args}
	end

	def progress_for_time(ship, time, forces \\ []) do
		GenServer.call(ship,{:progress_for_time,time,forces})
	end

	def current_position(ship) do
		GenServer.call(ship, {:current_position})
	end

	def handle_call({:progress_for_time, time, forces}, _from, state = %{massive: massive}) do
		updated_massive = Massive.progress_for_time(massive,time,forces)
		{:reply, Map.take(updated_massive,[:position, :mass]), %{state | massive: updated_massive}}
	end

	def handle_call({:current_position}, _from, state = %{massive: massive}) do
		{:reply,  Map.take(massive,[:position, :mass]), state}
	end
end
