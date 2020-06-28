defmodule Proj2.Gossip.Actor do
    use GenServer, restart: :transient
    
    def start_link(args) do
        GenServer.start_link(__MODULE__, args)
    end

    def init(num) do
        #IO.puts("Actor ##{num} Online!")
        {:ok, {num, [], 0, true, false}}
    end

    def handle_cast({:update_neighbor, list}, {num, _list, t, s, _has_started}) do
        if list == [] do
            #IO.puts("Actor ##{num} Offline due to empty neighbor list!")
            Proj2.Controller.actor_terminated(:no_neighbor, self())
            {:noreply, {num, list, t, false, true}}
        else
            {:noreply, {num, list, t, s, false}}
        end
    end

    def handle_cast({:message, pid}, {num, list, t, s, has_started}) do
        #IO.puts("Actor ##{num} is sending message")
        if !has_started do
            Proj2.Controller.actor_joining(self())
        end
        GenServer.cast(pid, :received)
        if s && t == 0 do
            GenServer.cast(
                Enum.random(list), 
                {:message, self()}
            )
        end
        next_s = if s && t >= 9 do
            #IO.puts("Actor ##{num} Offline due to condition reached!")
            Enum.each(list, fn neighbor -> GenServer.cast(neighbor, {:done, self()}) end)
            Proj2.Controller.actor_terminated(:on_condition, self())
            false
        else
            s
        end
        {:noreply, {num, list, t + 1, next_s, true}}
    end

    def handle_cast(:received, {num, list, t, s, has_started}) do
        #IO.puts("Actor ##{num} is receiving message")
        if !has_started do
            Proj2.Controller.actor_joining(self())
        end
        if s do
            GenServer.cast(
                Enum.random(list), 
                {:message, self()}
            )
        end
        {:noreply, {num, list, t, s, true}}
    end

    def handle_cast({:done, pid}, {num, list, t, s, has_started}) do
        list = list -- [pid]
        next_s = if s && length(list) == 0 do
            #IO.puts("Actor ##{num} Offline due to empty neighbor list!")
            Proj2.Controller.actor_terminated(:no_neighbor, self())
            false
        else
            s
        end
        {:noreply, {num, list, t, next_s, has_started}}
    end

end