defmodule Proj2 do
    use Application

    def main([actor_num, topology, algorithm]) do
        topology = if String.equivalent?(topology, "3Dtorus") do
            "torus3D"
        else
            topology
        end
        
        Proj2.start(:normal, {elem(Integer.parse(actor_num), 0), String.to_atom(topology), String.to_atom(algorithm)})
    end

    def start(_t, {actor_num, topology, algorithm}) do
        {:ok, pid} = Supervisor.start_link(
            [
                %{
                    id: Proj2.ActorSupervisor,
                    start: {Proj2.ActorSupervisor, :start_link, [:ok]}
                },
                %{
                    id: Proj2.Controller,
                    start: {Proj2.Controller, :start_link, [{actor_num, topology, algorithm}]}
                }
            ],
            [
                strategy: :one_for_all,
                name: Proj2.Supervisor
            ]
        )
        #IO.inspect Supervisor.count_children(pid)
        GenServer.call(Proj2.Controller, :start_actors, :infinity)
        wait(pid, 0)
        {:ok, pid}
    end

    def wait(pid, et) do
        :timer.sleep(2000)
        {start_time, end_time} = GenServer.call(Proj2.Controller, :check_status, :infinity)
        #IO.puts(actor_num)
        if end_time == nil do
            wait(pid, et)
        else 
            if et == end_time do
                IO.puts "Time Taken:"
                IO.puts "#{end_time - start_time} ms"
                GenServer.stop(pid)
            else
                wait(pid, end_time)
            end
        end
    end
end