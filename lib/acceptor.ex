# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)
defmodule Acceptor do

  def start config do
    if config.debug == 1, do:
      IO.puts "Acceptor created"
    next config, -1, MapSet.new
  end

  defp next config, ballot_num, accepted do
    receive do
      {:p1a, scount, ballot_temp} ->
        ballot_num = max(ballot_num, ballot_temp)
        if config.debug == 1, do:
          IO.puts "Acceptor send p1b to Scount"
        send scount, {:p1b, self(), ballot_num, accepted}
        next config, ballot_num, accepted

      {:p2a, commander, {ballot_temp, _, _} = pvalue} ->
        accepted =
          if ballot_temp == ballot_num do
            MapSet.put(accepted, pvalue)
          else
            accepted
          end
        if config.debug == 1, do:
          IO.puts "Accepter send p2b to commander"
        send commander, {:p2b, self(), ballot_num}
        next config, ballot_num, accepted
      _ -> 
        IO.puts "!Acceptor-next function received unexpected msg"
    end # end receive
    next config, ballot_num, accepted
  end #end def
end