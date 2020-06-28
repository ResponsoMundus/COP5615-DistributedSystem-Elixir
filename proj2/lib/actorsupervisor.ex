defmodule Proj2.ActorSupervisor do
    use DynamicSupervisor

    def start_link(init_arg) do
        DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    def init(_) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end

    def start_actor(algorithm, num) do
        {:ok, pid} = if algorithm == :gossip do
            DynamicSupervisor.start_child(__MODULE__, {Proj2.Gossip.Actor, num})
        else
            DynamicSupervisor.start_child(__MODULE__, {Proj2.PushSum.Actor, num})
        end
        pid
    end
end