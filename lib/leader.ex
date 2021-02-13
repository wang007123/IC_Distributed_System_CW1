defmodule Leader do

  def start config do
    ballot_num = {0, self()}
    receive do
      {:bind, acceptor, replica} ->
        spawn Scout, :start, [config, self(), acceptor, ballot_num]
        next config, ballot_num, false, MapSet.new, acceptor, replica
    end
  end

  def next config, ballot_num, active, proposals, acceptor, replicas do
    receive do
      {:propose, slot_num, command} ->
        # check {slot_num,command} in proposal
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
        proposals = update(proposals, pmax pvals)
        for {slot_num, command} <- Map.to_list(proposals) do
          spawn Commander, :start, [self(), acceptor, replicas, {ballot_num, slot_num, command}]
        end
        active = true
        next config, ballot_num, active, proposals, acceptor, replicas

      {:preempted, {r, leader}} ->
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
    end
  end

  #buhui
  defp pmax pvalues do
    max_ballot = Enum.map(pvalues, fn b -> {ballot_num, _, _}  end)

  end

  defp update x, y do
    for x do
      if Map.has_key?(x, slot_num) == true and Map.has_key?(y, slot_num) == false do
        map = Map.new(x, slot_num)
      end
    end
    Map.merge(map, y)
  end

end


