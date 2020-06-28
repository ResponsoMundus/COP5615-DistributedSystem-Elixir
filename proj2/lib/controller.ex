defmodule Proj2.Controller do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def actor_terminated(reason, pid) do
        GenServer.cast(__MODULE__, {:actor_terminate, reason, pid})
    end

    def actor_joining(pid) do
        GenServer.cast(__MODULE__, {:join_network, pid})
    end

    def deadend() do
        GenServer.cast(__MODULE__, :dead_end)
    end

    def init({actor_num, topology, algorithm}) do
        actor_num = cond do 
            topology == :torus3D ->
                trunc(:math.pow(:math.ceil(:math.pow(actor_num, 1/3)), 3))
            topology == :honeycomb || topology == :randhoneycomb ->
                trunc(:math.pow(:math.ceil(:math.pow(actor_num, 1/2)), 2))
            true ->
                actor_num
        end
        {:ok, {actor_num, topology, algorithm, nil, nil, []}}
    end

    def handle_call(:start_actors, _from, {actor_num, topology, algorithm, _st, _et, _n}) do
        pid_list = Enum.map(1..actor_num, fn n -> 
            Proj2.ActorSupervisor.start_actor(algorithm, n) 
        end)
        #IO.inspect pid_list

        neighbor_list = Proj2.Topology.generate_topology(pid_list, topology)
        #IO.inspect neighbor_list

        Enum.map(0..(actor_num - 1), fn x -> 
            GenServer.cast(Enum.at(pid_list, x), {:update_neighbor, Enum.at(neighbor_list, x)}) 
        end)
        #IO.puts "Updating neighbors of all actors"

        random_actor_index = Enum.random(1..actor_num) - 1
        random_actor = Enum.at(pid_list, random_actor_index)

        start_time = :os.system_time(:millisecond)

        if algorithm == :gossip do
            GenServer.cast(random_actor, :received)
        else
            GenServer.cast(random_actor, {:message,0, 0, 0})
        end

        if length(Enum.at(neighbor_list, random_actor_index)) == 0 do
            IO.inspect random_actor
            {:reply, :ok, {actor_num, topology, algorithm, start_time, nil, [random_actor]}}
        else
            {:reply, :ok, {actor_num, topology, algorithm, start_time, nil, []}}
        end
    end

    def handle_call(:check_status, _from, {actor_num, top, alg, start_time, end_time, started_actors}) do
        {:reply, {start_time, end_time}, {actor_num, top, alg, start_time, end_time, started_actors}}
    end

    def handle_cast({:join_network, pid}, {actor_num, top, alg, start_time, end_time, started_actors}) do
        {:noreply, {actor_num, top, alg, start_time, end_time, started_actors ++ [pid]}}
    end
    
    def handle_cast({:actor_terminate, _r}, {actor_num, top, alg, start_time, end_time, started_actors}) do
        {:noreply, {actor_num - 1, top, alg, start_time, end_time, started_actors}}
    end

    def handle_cast({:actor_terminate, _r, pid}, {actor_num, top, alg, start_time, _end_time, started_actors}) do
        #IO.puts "#{length(started_actors)}"
        #if length(started_actors) == 1 && Enum.at(started_actors, 0) == pid do
            #IO.puts "!!#{:os.system_time(:millisecond) - start_time}"
        #end
        end_time = :os.system_time(:millisecond)
        {:noreply, {actor_num - 1, top, alg, start_time, end_time, started_actors -- [pid]}}
    end

end