defmodule Leader do

  def start config do
    ballot_num = {0, self()}
    IO.puts "Leader created"
    receive do
      {:BIND, acceptor, replica} ->
        spawn Scout, :start, [config, self(), acceptor, ballot_num]
        next config, ballot_num, false, MapSet.new, acceptor, replica
      _ -> 
        IO.puts "Leader received unexpected msg"
    end
  end

  def next config, ballot_num, active, proposals, acceptor, replicas do
    receive do
      {:propose, slot_num, command} ->
        # check {slot_num,command} in proposal
        IO.puts "Leader received proposals from replica"
        proposals =
          if !Map.has_key?(proposals, slot_num) do
            proposals.put(proposals, slot_num, command)
            if active == true do
              spawn Commander, :start, [config, self(), acceptor, replicas, {ballot_num, slot_num, command}]
            end
          else
            proposals
          end
        next config, ballot_num, active, proposals, acceptor, replicas

      # has problem
      {:adopted, ballot_num, pvals} ->
        IO.puts " leader receive adopted from Scout"
        proposals = update(proposals, pmax pvals)
        send config.monitor, { :SCOUT_FINISHED, config.node_num }
        for {slot_num, command} <- Map.to_list(proposals) do
          spawn Commander, :start, [config, self(), acceptor, replicas, {ballot_num, slot_num, command}]
        end
        active = true
        next config, ballot_num, active, proposals, acceptor, replicas

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
      _ -> IO.puts "!Leader-next function received unexpected msg"
    end
  end

  defp pmax pvals do
    MapSet.new(for {b, s, c} <- pvals, Enum.all?(pvals, fn {b_prime, s_prime, _} -> s != s_prime or b_prime <= b end), do: {b, s, c})
  end

  # The update function applies to two sets of proposals.
  # Returns the elements of y as well as the elements
  # of x that are not in y.
  # Warning: this is not union! When talking about
  # elements of y, we refer to fst p, where p is a
  # pair in y
  defp update(x, y) do
    res = MapSet.new(for {s, elem} <- x, !Enum.find(y, fn p -> match?({^s, _}, p) end), do: {s, elem})
    MapSet.union(res, MapSet.new(y))
  end


end


