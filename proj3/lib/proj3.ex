defmodule Proj3 do

    def initialize(num_nodes, num_requests) do
        {:ok, _pid} = Supervisor.start_link(
            [
                %{
                    id: Proj3.ActorSupervisor,
                    start: {Proj3.ActorSupervisor, :start_link, [:ok]}
                },
                %{
                    id: Proj3.Controller,
                    start: {Proj3.Controller, :start_link, [{num_nodes, num_requests}]}
                }
            ],
            [
                strategy: :one_for_all,
                name: Proj3.Supervisor
            ]
        )
        GenServer.call(Proj3.Controller, :start_actors, :infinity)
        
        wait()
    end

    def wait() do
        {num_nodes, terminated_num} = GenServer.call(Proj3.Controller, :get_status)
        # IO.puts "!!#{num_nodes} #{terminated_num}!!"
        if num_nodes > terminated_num do
            :timer.sleep(1000)
            wait()
        # else
            # IO.puts "!!#{num_nodes} #{terminated_num}!!"
        else
            {ave, max} = GenServer.call(Proj3.Controller, :get_results, :infinity)
            IO.puts "Average number of hops : #{ave}"
            IO.puts "Maximum number of hops : #{max}"
        end
    end

end
