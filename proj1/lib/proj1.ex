defmodule Proj1 do
    use GenServer

    def start_link([actor_num, from, to, another_machine]) do
        GenServer.start_link(__MODULE__, [actor_num, from, to, another_machine], name: __MODULE__)
    end

    def init([actor_num, from, to, another_machine]) do
        factor_start = trunc(:math.pow(10, :math.ceil(length(Integer.to_charlist(from))/2) - 1))
        factor_end = trunc(:math.sqrt(to))
        step = div(factor_end - factor_start, actor_num)

        #Assigning work according to all the possible factors
        create_worker(factor_start, factor_end, step, actor_num - 1, from, to, another_machine)

        {:ok, {actor_num, []}}
    end

    def handle_call({:complete, result_list}, _from, state) do
        {:reply, elem(state, 0) - 1, {elem(state, 0) - 1, elem(state, 1) ++ result_list}}
    end

    def handle_call(:get_state, _from, state) do
        {:reply, elem(state, 0), state}
    end

    def handle_call(:print, _from, state) do
        raw_result = elem(state, 1)
        vampire_number_list =  Enum.map(raw_result, fn x -> hd(x) end)
        sorted_vampire_number_list = Enum.sort(Enum.uniq(vampire_number_list))
        result = Enum.map(sorted_vampire_number_list, fn x -> get_full_factors(x, raw_result) end)

        final_log = Enum.reduce(result, "", fn x1, acc1 -> acc1 <> Enum.reduce(x1, "", fn x2, acc2 -> acc2 <> "#{x2} " end) <> "\n" end)
        IO.puts(final_log)
        #IO.puts(length(result))
        {:stop, :normal, nil, state}
    end

    def wait() do
        reply = GenServer.call(__MODULE__, :get_state)
        #IO.puts reply
        if reply != 0 do
            :timer.sleep(100)
            wait()
        else
            GenServer.call(__MODULE__, :print)
        end
    end
    
    def create_worker(factor_start, factor_end, step, actors_left, min_product, max_product, another_machine) do
        decide_worker_location(factor_start, factor_start + step - 1, actors_left, min_product, max_product, another_machine)
		#IO.puts "create worker from #{factor_start} to #{factor_start + step - 1}"
        if (actors_left == 1) do
            decide_worker_location(factor_start + step, factor_end, actors_left, min_product, max_product, another_machine)
			#IO.puts "create worker from #{factor_start + step} to #{factor_end}"
        else 
            if (actors_left != 0) do
                create_worker(factor_start + step, factor_end, step, actors_left - 1, min_product, max_product, another_machine)
            end
        end
    end

    def decide_worker_location(from, to, actors_left, min_product, max_product, another_machine) do
        if another_machine == nil do
            spawn(Proj1, :check_range, [from, to, min_product, max_product])
        else
            if (rem(actors_left, 2) == 0) do 
                Node.spawn(another_machine, Proj1, :check_range, [from, to, min_product, max_product])
            else
                spawn(Proj1, :check_range, [from, to, min_product, max_product])
            end 
        end
    end

    #Check if there exists vampire number considering factor_start to factor_end
    def check_range(factor_start, factor_end, min_product, max_product) do
        actor_res_list = Enum.map(factor_start..factor_end, fn x -> Proj1.check_vampire_factor(x, trunc(:math.pow(10, length(Integer.to_charlist(x)))) - 1, min_product, max_product) end)
		actor_res_list = Enum.reduce(actor_res_list, [], fn x, acc -> acc ++ x end)
		#IO.inspect actor_res_list
        res_list = Enum.filter(actor_res_list, & length(&1) != 0)
        GenServer.multi_call(__MODULE__, {:complete, res_list})
        #if reply == 0 do
        #   GenServer.cast(__MODULE__, :print)
        #end
    end

    def get_full_factors(vampire_number, raw_result) do
        factor_list = Enum.filter(raw_result, & hd(&1) == vampire_number)
        Enum.reduce(factor_list, [vampire_number], fn x, acc ->
            acc ++ tl(x)
        end)
    end

    def check_vampire_factor(n, max_factor, min_product, max_product) do
		#IO.puts("check_vampire_factor from #{n} to #{max_factor}, products in #{min_product} and #{max_product}")
        cur_list = Enum.map(n..max_factor, fn x -> check_factors_and_product(n, x, n * x, min_product, max_product) end)
        Enum.filter(cur_list, & length(&1) != 0)
    end

    def check_factors_and_product(factor1, factor2, product, min_product, max_product) do
        if product >= min_product && product <= max_product
        && length(Integer.to_charlist(product)) == length(Integer.to_charlist(factor1)) + length(Integer.to_charlist(factor2)) && length((Integer.to_charlist(product) -- Integer.to_charlist(factor1)) -- Integer.to_charlist(factor2)) == 0 do
            #IO.puts "#{product}, #{factor1}, #{factor2}"
			[product, factor1, factor2]
        else
            []
        end
    end
end