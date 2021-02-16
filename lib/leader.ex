defmodule Leader do

  def start config do
    ballot_num = {0, self()}
    IO.puts "Leader created"
    receive do
      {:BIND, acceptor, replica} ->
        spawn Scout, :start, [config, self(), acceptor, ballot_num]
        next config, ballot_num, false, %{}, acceptor, replica
      _ -> 
        IO.puts "Leader received unexpected msg"
    end
  end

  defp next config, ballot_num, active, proposals, acceptor, replicas do
    receive do
      {:propose, s, c} ->
        # check {s,c} in proposal
        IO.puts "Leader received proposals (#{s}) from replica"
        proposals =
          if !Map.has_key?(proposals, s) do
            Map.put(proposals, s, c)
            if active == true do
              spawn Commander, :start, [config, self(), acceptor, replicas, {ballot_num, s, c}]
            end
          else
            proposals
          end
        next config, ballot_num, active, proposals, acceptor, replicas


      {:adopted, ballot, pvals} ->
        proposals = update proposals, pmax MapSet.to_list(pvals)
        send config.monitor, { :SCOUT_FINISHED, config.node_num }
        IO.puts "creating Commander"
        IO.inspect proposals
        for {s, c} <- Map.to_list(proposals) do

          IO.puts " leader creating Commander with slot (#{s},#{c}) from Scout"
          spawn Commander, :start, [config, self(), acceptor, replicas, {ballot, s, c}]
        end
        active = true
        next config, ballot, active, proposals, acceptor, replicas

      {:preempted, {r, leader}} ->
        IO.puts "Leader receive preempted"
        {ballot_num, active} =
          if {r, leader} > ballot_num do
            active = false
            ballot_num = {r + 1, self()}
            spawn Scout, :start, [self(), acceptor, ballot_num]
            {ballot_num, active}
          else
            {ballot_num, active}
          end
        next config, ballot_num, active, proposals, acceptor, replicas
      _ -> 
        IO.puts "!Leader-next function received unexpected msg"
    end #end receive
    next config, ballot_num, active, proposals, acceptor, replicas
  end # end defp

  defp pmax pvalues do
    max_ballot_number =
      Enum.map(pvalues, fn ({ b, _, _ }) -> b end) |> Enum.max(fn -> -1 end)

    Enum.filter(pvalues, fn ({ b, _, _ }) -> b == max_ballot_number end)
    |> Enum.map(fn ({ _, s, c }) -> { s, c } end) |> Map.new
  end

  defp update x, y do
    Map.merge y, x, fn _, c, _ -> c end
  end
end


