# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)
defmodule Commander do

def start config, leader, acceptors, replicas, {b, s, c} do
	if config.debug == 1, do:
		IO.puts "Commander created"
	for acceptor <- acceptors do
		send acceptor, {:p2a, self(),{b, s, c}}
	end
    send config.monitor, { :COMMANDER_SPAWNED, config.node_num }
	next config, MapSet.new(acceptors), leader,acceptors, replicas, {b, s, c}
end

defp next config, waitfor, leader,acceptors, replicas, {b, s, c} do
	receive do
		{:p2b, a, b_} ->
			if config.debug == 1, do:
				IO.puts "Commander receive p2b"
			if b_ == b do
				waitfor = MapSet.delete(waitfor, a)
				#IO.inspect (IEx.Info.info(acceptors))
				if 2 * MapSet.size(waitfor) < length(acceptors) do
					if config.debug == 1, do:
						IO.puts "Commander send decision to replica"
					for replica <- replicas do
						send replica, {:decision, s, c}
					end
			        send config.monitor, { :COMMANDER_FINISHED, config.node_num }
					exit(:normal)
				end
				next config, waitfor, leader,acceptors, replicas, {b, s, c}
			else
				if config.debug == 1, do:
					IO.puts "Commander send preempted to leader"
				send leader, {:preempted, b_}
				send config.monitor, { :COMMANDER_FINISHED, config.node_num }
				exit(:normal)
			end
		_ -> 
			IO.puts "!Commander-next function received unexpected msg"
	end #end receive
end # end defp


end #end defmodule