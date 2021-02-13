defmodule Acceptor do

  def start config do
    next -1, MapSet.new
  end

  def next config, ballot_num, accepted do
    receive do
      {:p1a, ballot_temp, identifier} ->
        ballot_num = max(ballot_num, ballot_temp)
        #        if ballot_temp > ballot_num do
        #           ballot_temp
        #        else
        #          ballot_num = ballot_num
        #        end
        send identifier, {:p1b, self(), ballot_num, accepted}
        next config, ballot_num, accepted

      {:p2a, identifier, {ballot_temp, slot_num, command} = pvalue} ->
        accepted =
          if ballot_temp == ballot_num do
            MapSet.put(accepted, pvalue)
          else
            accepted
          end
        send identifier, {:p2b, self(), ballot_num}
        next config, ballot_num, accepted
    end
  end
end
