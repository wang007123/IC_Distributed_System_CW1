# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)
defmodule Leader do

  def start config do
    ballot_num = {0, self()}
    if config.debug == 1, do:
      IO.puts "Leader created"
    receive do
      {:BIND, acceptor, replica} ->
        spawn Scout, :start, [config, self(), acceptor, ballot_num]
        next config, ballot_num, false, %{}, acceptor, replica
      _ -> 
        IO.puts "Leader received unexpected msg"
    end
  end

  defp next config, ballot_num, active, proposals_map, acceptor, replicas do
    receive do
      {:propose, s, c} ->
        #if config.debug == 1, do: 
         # IO.puts "Leader received proposals_map (#{s}) from replica"
        proposals_map =
          if !Map.has_key?(proposals_map, s) do
            if active == true do
              spawn Commander, :start, [config, self(), acceptor, replicas, {ballot_num, s, c}]
            end
            Map.put(proposals_map, s, c)
          else
            proposals_map
          end
        next config, ballot_num, active, proposals_map, acceptor, replicas


      {:adopted, ballot, pvals} ->
        proposals_map = update proposals_map, pmax MapSet.to_list(pvals)
        if config.debug == 1, do:
            IO.puts " leader creating Commander"
        for {s, c} <- Map.to_list(proposals_map) do
          spawn Commander, :start, [config, self(), acceptor, replicas, {ballot, s, c}]
        end
        active = true
        next config, ballot, active, proposals_map, acceptor, replicas

      {:preempted, {r, _} = ballot_tmp} ->
        if config.debug == 1, do:
          IO.puts "Leader receive preempted"
        {ballot_num, active} =
          if ballot_tmp > ballot_num do
            ballot_num = {r + 1, self()}
            #sleep random time for live lock
            Process.sleep(Util.random(2000))
            spawn Scout, :start, [config,self(), acceptor, ballot_num]
            active = false
            {ballot_num, active}
          else
            {ballot_num, active}
          end
        next config, ballot_num, active, proposals_map, acceptor, replicas
      _ -> 
        IO.puts "!Leader-next function received unexpected msg"
    end #end receive
    next config, ballot_num, active, proposals_map, acceptor, replicas
  end # end defp

  defp pmax pvals do
    pvals_first_element = Enum.map(pvals, fn ({ b, _, _ }) -> b end)
    pvals_max_first_element = Enum.max(pvals_first_element,fn -> -1 end)
    pvals_max_matached = Enum.filter(pvals, fn ({ tmp_b, _, _ }) -> tmp_b == pvals_max_first_element end)
    max_pvals_s_c = Enum.map(pvals_max_matached,fn ({ _, tmp_s, tmp_c }) -> { tmp_s, tmp_c } end) 
    Map.new(max_pvals_s_c)
  end

  defp update x, y do
    Map.merge y, x, fn _, tmp_c, _ -> tmp_c end
  end
end
