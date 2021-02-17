# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)
defmodule Scout do

def start config, leader, acceptors, ballot do
	if config.debug == 1, do:
		IO.puts "Scout created"
	for acceptor <- acceptors do
		send acceptor, {:p1a, self(), ballot}
	end
	send config.monitor, { :SCOUT_SPAWNED, config.node_num }
	next config, MapSet.new(acceptors), MapSet.new, ballot, leader, acceptors

end

defp next config, waitfor, pvalues, ballot, leader, acceptors do
	receive do
		{:p1b, a, b,r} ->
			if config.debug == 1, do:
			#IO.inspect b
			#IO.inspect ballot
				IO.puts "Scount receive p1b from Acceptors"
			if b == ballot do
				#IO.puts "------a,b,r,pvalues,waitfor shown as below"
				pvalues = MapSet.union(pvalues,r)
				waitfor = MapSet.delete(waitfor,a)
				if 2* MapSet.size(waitfor) < length(acceptors) do
					if config.debug == 1, do:
						IO.puts "Scout sent adopted to leader"
					send leader, {:adopted, b, pvalues}
	            	send config.monitor, { :SCOUT_FINISHED, config.node_num }
					exit(:normal)
				else
					if config.debug == 1, do:
						IO.puts "Scout recursive"
		        	next config, waitfor, pvalues, ballot, leader, acceptors
	      		end
			else
				if config.debug == 1, do:
					IO.puts "Scout sent preempted to leader"
				send leader, {:preempted, b}
            	send config.monitor, { :SCOUT_FINISHED, config.node_num }
				exit(:normal)
			end
		_ -> 
			IO.puts "!Scout-next function received unexpected msg"
	end #end receive
end #end defp

end #end defmodule