defmodule Proj3.Actor do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, args)
    end

    def init({id, oid, requests}) do
        state = %{
            "id"                 => id,
            "oid"                => oid,
            "pid"                => self(),
            "request_list"       => requests,
            "request_num"        => length(requests),
            "neighbor_set"       => [],
            "object_pointer_set" => %{},
            "back_pointer_set"   => [],
            "neighbor_table"     => Enum.map(0..3, fn _i -> Enum.map(0..15, fn _j -> nil end) end),
            "current_ack_actor"  => nil,
            "hop_count"          => []
        }
        {:ok, state}
    end

    def handle_call({:get_surrogate, {actor_id, actor_pid}}, _from, state) do
        level = get_same_prefix_length(actor_id, state["id"])
        {next_hop_id, next_hop_pid} = next_hop(level, actor_id, state["id"], state["neighbor_table"])
        if next_hop_id == state["id"] do
            {:reply, {next_hop_id, next_hop_pid}, state}
        else
            next_hop = GenServer.call(next_hop_pid, {:get_surrogate, {actor_id, actor_pid}})
            {:reply, next_hop, state}
        end
    end

    def handle_call({:insert, {actor_id, actor_pid, parent_list}}, _from, state) do
        if state["current_ack_actor"] == actor_id or state["id"] == actor_id do
            # Actor has been reached
            {:reply, :ok, state}
        else
            state = Map.put(state, "current_ack_actor", actor_id)

            # Actors reached by the multicast contact N and become an initial neighbor set
            same_prefix_length = get_same_prefix_length(state["id"], actor_id)
            GenServer.cast(actor_pid, {:add_neighbor, {state["id"], state["pid"], same_prefix_length}})

            # Add actor_id to routing table 
            neighbor_table = state["neighbor_table"]
            neighbor_table = if Enum.at(Enum.at(neighbor_table, same_prefix_length), Enum.at(actor_id, same_prefix_length)) == nil do
                update_list = Enum.at(neighbor_table, same_prefix_length)
                update_list = List.replace_at(update_list, Enum.at(actor_id, same_prefix_length), {actor_id, actor_pid})
                # Update back pointer
                GenServer.cast(actor_pid, {:add_back_pointer, {state["id"], state["pid"]}})
                List.replace_at(neighbor_table, same_prefix_length, update_list)
            else
                neighbor_table
            end
            state = Map.put(state, "neighbor_table", neighbor_table)

            # Transfer references of locally rooted pointers as necessary
            Enum.map(state["object_pointer_set"], fn {object_id, {des_id, des_pid}} -> 
                if get_same_prefix_length(object_id, actor_id) > get_same_prefix_length(object_id, state["id"]) do
                    GenServer.cast(actor_pid, {:add_object_pointer, {object_id, {des_id, des_pid}}})
                end
            end)

            next_parent_list = parent_list ++ [state["id"]]

            # Find all existing actors sharing the same prefix
            if hd(state["id"]) == hd(actor_id) do
                Enum.map(1..3, fn i -> 
                    Enum.map(0..15, fn j -> 
                        cur = Enum.at(Enum.at(state["neighbor_table"], i), j)
                        if cur != nil and elem(cur, 0) != actor_id and length(next_parent_list -- [elem(cur, 0)]) == length(next_parent_list) do
                            GenServer.call(elem(cur, 1), {:insert, {actor_id, actor_pid, next_parent_list}})
                        end 
                    end) 
                end)
            end

            {:reply, :ok, state}
        end
    end

    def handle_call({:get_hop_count}, _from, state) do
        {:reply, state["hop_count"], state}
    end

    def handle_call({:get_back_pointer_set}, _from, state) do
        {:reply, state["back_pointer_set"], state}
    end

    def handle_call({:join_network, level}, _from, state) do
        state = join_network({level, state})
        {:reply, :ok, state}
    end

    def handle_cast({:add_neighbor, {neighbor_id, neighbor_pid, prefix_len}}, state) do
        state = Map.put(state, "neighbor_set", (state["neighbor_set"] -- [{neighbor_id, neighbor_pid, prefix_len}]) ++ [{neighbor_id, neighbor_pid, prefix_len}])
        {:noreply, state}
    end

    def handle_cast({:add_back_pointer, {bp_id, bp_pid}}, state) do
        state = Map.put(state, "back_pointer_set", (state["back_pointer_set"] -- [{bp_id, bp_pid}]) ++ [{bp_id, bp_pid}])
        {:noreply, state}
    end
    
    def handle_cast({:add_object_pointer, {object_id, {des_id, des_pid}}}, state) do
        state = Map.put(state, "object_pointer_set", Map.update(state["object_pointer_set"], {des_id, des_pid}, object_id, fn _ -> {des_id, des_pid} end))
        {:noreply, state}
    end

    def handle_cast({:get_status}, state) do
        IO.inspect(state)
        {:noreply, state}
    end

    def handle_cast({:request, hop_count, level, {object_id, source_pid}}, state) do
        {next_hop_id, next_hop_pid} = if object_id in Map.keys(state["object_pointer_set"]) do
            state["object_pointer_set"][object_id]
        else
            level = if get_same_prefix_length(object_id, state["id"]) > level do
                get_same_prefix_length(object_id, state["id"])
            else
                level
            end
            next_hop(level, object_id, state["id"], state["neighbor_table"])
        end
        if next_hop_id == state["id"] do
            GenServer.cast(source_pid, {:response, hop_count})
            {:noreply, state}
        else
            GenServer.cast(next_hop_pid, {:request, hop_count + 1, level + 1, {object_id, source_pid}})
            {:noreply, state}
        end
    end

    def handle_cast({:response, hop_count}, state) do
        state = Map.put(state, "hop_count", state["hop_count"] ++ [hop_count])
        if state["request_num"] - 1 == 0 do
            GenServer.cast(Proj3.Controller, :terminate_actor)
        end
        {:noreply, Map.put(state, "request_num", state["request_num"] - 1)}
    end

    def handle_cast({:publish, hop_count, level, object_id, id, pid}, state) do
        state = Map.put(state, "object_pointer_set", Map.put(state["object_pointer_set"], object_id, {id, pid}))
        # level = get_same_prefix_length(object_id, state["id"])
        # IO.inspect {:publish, state["id"], level, object_id, id, pid}
        {next_hop_id, next_hop_pid} = next_hop(level, object_id, state["id"], state["neighbor_table"])
        if next_hop_id != state["id"] do
            GenServer.cast(next_hop_pid, {:publish, hop_count + 1, level + 1, object_id, id, pid})
        else
            GenServer.cast(pid, {:published, hop_count})
            GenServer.cast(Proj3.Controller, :published)
        end
        
        {:noreply, state}
    end

    def handle_cast({:published, hop_count}, state) do
        state = Map.put(state, "hop_count", state["hop_count"] ++ [hop_count])
        {:noreply, state}
    end

    def handle_cast({:start_publishing}, state) do
        GenServer.cast(self(), {:publish, 0, 0, state["oid"], state["id"], self()})
        {:noreply, state}
    end

    def handle_info({:send_request, i}, state) do
        if i < length(state["request_list"]) do
            object_id = Enum.at(state["request_list"], i)
            GenServer.cast(self(), {:request, 0, 0, {object_id, self()}})
            Process.send_after(self(), {:send_request, i + 1}, 1000)
        end
        {:noreply, state}
    end

    def get_same_prefix_length(id1, id2) do
        if length(id1) != 0 and hd(id1) == hd(id2) do
            1 + get_same_prefix_length(tl(id1), tl(id2))
        else
            0
        end
    end

    def join_network({level, state}) do
        # Find closest k neighbors
        neighbor_set = state["neighbor_set"] -- [{state["id"], state["pid"], 4}]
        max_prefix_len = Enum.reduce(neighbor_set, 0, fn {_id, _pid, prefix_len}, len -> max(len, prefix_len) end)
        level = min(level, max_prefix_len)
        cloest_k_neighbors = Enum.reduce(neighbor_set, [], fn {neighbor_id, neighbor_pid, prefix_len}, list -> 
            if prefix_len == level do [{neighbor_id, neighbor_pid, prefix_len}] ++ list else list end
        end)

        #if level == 0 do
        #    IO.inspect cloest_k_neighbors
        #end

        # Fill the level p of neighbor table
        neighbor_table = Enum.reduce(cloest_k_neighbors, state["neighbor_table"], fn {neighbor_id, neighbor_pid, _prefix_len}, neighbor_table -> 
            if Enum.at(Enum.at(neighbor_table, level), Enum.at(neighbor_id, level)) == nil do 
                update_list = Enum.at(neighbor_table, level)
                update_list = List.replace_at(update_list, Enum.at(neighbor_id, level), {neighbor_id, neighbor_pid})
                # Update back pointer
                GenServer.cast(neighbor_pid, {:add_back_pointer, {state["id"], state["pid"]}})
                List.replace_at(neighbor_table, level, update_list)
            else
                neighbor_table
            end
        end)
        
        # Find all actors pointing to the closest k neighbors
        total_pointer_set = Enum.reduce(cloest_k_neighbors, [], fn neighbor, list -> 
            neighbor_bp_set = GenServer.call(elem(neighbor, 1), {:get_back_pointer_set})
            list ++ neighbor_bp_set
        end)
        total_pointer_set = Enum.uniq(total_pointer_set)
        total_pointer_set = Enum.map(total_pointer_set, fn {bp_id, bp_pid} ->
            {bp_id, bp_pid, get_same_prefix_length(bp_id, state["id"])}
        end)

        # Update state
        state = Map.put(state, "neighbor_table", neighbor_table)
        state = Map.put(state, "neighbor_set", total_pointer_set)

        # Fill p - 1 level of neighbor table
        if level != 0 do
            join_network({level - 1, state})
        else
            state
        end
    end

    def next_hop(level, target_id, id, neighbor_table) do
        if level == 4 do
            {id, self()}
        else
            d = Enum.at(target_id, level)
            e = check_next_elem_in_same_level(d, level, id, self(), Enum.at(neighbor_table, level))
            if elem(e, 1) == self() do
                next_hop(level + 1, target_id, id, neighbor_table)
            else
                e
            end
        end
    end

    def check_next_elem_in_same_level(d, level, id, pid, neighbor_list) do
        e = Enum.at(neighbor_list, d)
        cond do
            e != nil -> e
            e == nil and d == Enum.at(id, level) -> {id, pid}
            e == nil -> check_next_elem_in_same_level(rem(d + 1, 16), level, id, pid, neighbor_list)
        end
    end

end