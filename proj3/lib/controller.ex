defmodule Proj3.Controller do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init({num_nodes, num_requests}) do
        {:ok, {num_nodes, num_requests, 0, 0, [], nil}}
    end

    def handle_call(:start_actors, _from, {num_nodes, num_requests, num_terminated, num_published, _pid_list, _start_time}) do
        start_time = :os.system_time(:millisecond)
        IO.puts "Start constructing network"
        id_list = generate_id_list(num_nodes)
        oid_list = Enum.shuffle(id_list)
        #id_list = [[0,0,0,1],[1,1,1,1],[2,0,1,1]]
        pid_list = Enum.map(0..(num_nodes - 1), fn i ->
            id = Enum.at(id_list, i)
            oid = Enum.at(oid_list, i)
            requests = Enum.map(0..num_requests, fn _ -> Enum.random(oid_list) end)
            Proj3.ActorSupervisor.start_actors({id, oid, requests})
        end)

        # Insert actors into the network
        Enum.reduce(0..(length(id_list) - 1), nil,  fn i, first -> 
            cur_id = Enum.at(id_list, i)
            cur_pid = Enum.at(pid_list, i)
            
            # If it's not the first node
            first = if first != nil do
                # Find surrogate
                {_surrogate_id, surrogate_pid} = GenServer.call(elem(first, 1), {:get_surrogate, {cur_id, cur_pid}})
                GenServer.call(surrogate_pid, {:insert, {cur_id, cur_pid, [cur_id]}})
                first
            else
                {cur_id, cur_pid}
            end
            
            GenServer.call(cur_pid, {:join_network, 3})
            first
        end)

        IO.puts "Network constructed"
        IO.puts "Start publishing objects"

        Enum.map(pid_list, fn pid -> 
            GenServer.cast(pid, {:start_publishing}) 
        end)

        # Check status for each actors, used for debugging
        # Enum.map(pid_list, fn pid -> GenServer.cast(pid, {:get_status}) end)
        
        {:reply, :ok, {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}}
    end

    def handle_call(:get_status, _from, {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}) do
        {:reply, {num_nodes, num_terminated}, {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}}
    end

    def handle_call(:get_results, _from, {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}) do
        {total_hops, max_hop} = Enum.reduce(pid_list, {0, 0}, fn pid, {count, max_hop} -> 
            hop_count_list = GenServer.call(pid, {:get_hop_count})
            s = Enum.sum(hop_count_list)
            m = Enum.max(hop_count_list)
            max_hop = if m > max_hop do
                m
            else
                max_hop
            end
            {count + s, max_hop}
        end)
        {:reply, {total_hops / num_nodes / num_requests, max_hop} , {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}}
    end

    def handle_cast(:published, {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}) do
        if num_nodes == num_published + 1 do
            IO.puts "All objects published"
            IO.puts "Start sending requests"
            Enum.map(pid_list, fn pid -> 
                # GenServer.cast(pid, {:start_requesting}) 
                send(pid, {:send_request, 0})
            end)
        end
        {:noreply, {num_nodes, num_requests, num_terminated, num_published + 1, pid_list, start_time}}
    end
    
    def handle_cast(:terminate_actor, {num_nodes, num_requests, num_terminated, num_published, pid_list, start_time}) do
        if num_nodes == num_terminated + 1 do
            IO.puts "All requests have been served"
            IO.puts "#{(:os.system_time(:millisecond) - start_time) / 1000} seconds taken"
        end
        
        {:noreply, {num_nodes, num_requests, num_terminated + 1, num_published, pid_list, start_time}}
    end

    def generate_id_list(num_nodes) do
        # id is a 4-digit list
        # possible_id_list = [[1,15,14,10], [2,2,1,12], ...]
        possible_id_list = Enum.shuffle(generate_possible_id_list(4))
        Enum.map(0..(num_nodes - 1), fn i -> Enum.at(possible_id_list, i) end)
    end

    def generate_possible_id_list(digits) do
        elem_list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        if digits == 1 do
            Enum.map(elem_list, fn elem -> [elem] end)
        else
            tail_list = generate_possible_id_list(digits - 1)
            Enum.reduce(elem_list, [], fn i, list ->
                list ++ Enum.map(tail_list, fn tail -> [i] ++ tail end) 
            end)
        end
    end

end