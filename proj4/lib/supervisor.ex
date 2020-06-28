defmodule Proj4.ActorSupervisor do
    use DynamicSupervisor

    def start_link(init_arg) do
        DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    @impl true
    def init(_) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end
    
    def start_server() do
        elem(DynamicSupervisor.start_child(__MODULE__, {Proj4.Server, {}}), 1)
    end
    
    def start_clients(clients_num, server_pid) do
        Enum.map(1..clients_num, fn _i -> 
            elem(DynamicSupervisor.start_child(__MODULE__, {Proj4.Client, {server_pid}}), 1)
        end)
    end

end