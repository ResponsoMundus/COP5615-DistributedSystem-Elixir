defmodule Proj2.PushSum.Actor do
    use GenServer, restart: :transient
    
    def start_link(args) do
        GenServer.start_link(__MODULE__, args)
    end

    def init(num) do
        #IO.puts("Actor ##{num} Online!")
        {:ok, {num, [], num, 1, 0, true, false}}
    end

    def handle_cast({:update_neighbor, list}, {num, _list, s, w, t, st, _has_started}) do
        if list == [] do
            #IO.puts("Actor ##{num} Offline due to empty neighbor list!")
            Proj2.Controller.actor_terminated(:no_neighbor, self())
            {:noreply, {num, list, s, w, t, false, true}}
        else
            {:noreply, {num, list, s, w, t, st, false}}
        end
    end

    def handle_cast({:message, hs, hw, _n}, {num, list, s, w, t, st, has_started}) do
        if !has_started do
            Proj2.Controller.actor_joining(self())
        end
        if st do
            next_s = (s + hs) / 2
            next_w = (w + hw) / 2
            diff = abs(s / w - next_s / next_w)
            

            {next_t, next_st} = if diff >= :math.pow(10, -10) do
                {0, st}
            else
                if t == 2 do
                    #IO.puts("Actor ##{num} Offline due to condition reached!")
                    #IO.puts("#{next_s} #{next_w}")
                    #IO.puts(next_s / next_w)
                    Enum.each(list, fn neighbor -> GenServer.cast(neighbor, {:done, self()}) end)
                    Proj2.Controller.actor_terminated(:on_condition, self())
                    {t + 1, false}
                else
                    {t + 1, st}
                end
            end

            GenServer.cast(
                Enum.random(list), 
                {:message, next_s, next_w, num}
            )

            {:noreply, {num, list, next_s, next_w, next_t, next_st, true}}
        else
            #IO.puts "Actor ##{num} hears form Actor ##{n}"
            #Proj2.Controller.deadend();
            #IO.puts("===============================")
            {:noreply, {num, list, s, w, t, st, true}}
        end
    end

    def handle_cast({:done, pid}, {num, list, s, w, t, st, has_started}) do
        list = list -- [pid]
        next_st = if st && length(list) == 0 do
            #IO.puts("Actor ##{num} Offline due to empty neighbor list!")
            Proj2.Controller.actor_terminated(:no_neighbor, self())
            false
        else
            st
        end
        if has_started && st do
            {:noreply, {num, list, s, w, t, next_st, has_started}}
        else
            {:noreply, {num, list, s, w, t, next_st, has_started}}
        end
    end
end