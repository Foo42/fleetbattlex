defmodule Fleetbattlex.Ship do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive

	def start_link(name, params) do
		GenServer.start_link(__MODULE__,%{massive: params}, name: via_name(name))
	end

	def init(args) do
		{:ok, args}
	end

	def progress_for_time(ship, time, forces \\ []) do
		GenServer.call(via_name(ship),{:progress_for_time,time,forces})
	end

	def current_position(ship) do
		GenServer.call(via_name(ship), {:current_position})
	end

	def start_burn(ship, burn) do
		GenServer.call(via_name(ship), {:start_burn, burn})
	end

	def list_burns(ship), do: GenServer.call(via_name(ship), {:list_burns})

	def handle_call({:progress_for_time, time, forces}, _from, state = %{massive: massive}) do
		updated_massive = Massive.progress_for_time(massive,time,forces)
		{:reply, Map.take(updated_massive,[:position, :mass]), %{state | massive: updated_massive}}
	end

	def handle_call({:start_burn, burn}, _from, state) do
		current_burns = state |> Dict.get(:burns,[])
		new_burns = [burn|current_burns]
		new_state = state |> Dict.put(:burns, new_burns)
		{:reply, :ok, new_state}
	end

	def handle_call({:list_burns}, _from, state), do: {:reply, state.burns, state}

	def handle_call({:current_position}, _from, state = %{massive: massive}) do
		{:reply,  Map.take(massive,[:position, :mass]), state}
	end

	defp via_name(name), do: {:via, :gproc, {:n, :l, name}}
end
