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

	def handle_call({:progress_for_time, time, forces}, state = %{massive: massive}) do
		updated_massive = Massive.progress_for_time(massive,time,forces)
		summary = %{position: updated_massive.position, mass: updated_massive.mass}
		{:reply, summary, %{state | massive: updated_massive}}
	end

end
