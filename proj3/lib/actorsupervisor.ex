defmodule Proj3.ActorSupervisor do
    use DynamicSupervisor

    def start_link(init_arg) do
        DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    @impl true
    def init(_) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end

    def start_actors({id, oid, requests}) do
        elem(DynamicSupervisor.start_child(__MODULE__, {Proj3.Actor, {id, oid, requests}}), 1)
    end

end