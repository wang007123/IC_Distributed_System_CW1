defmodule Scout do

def start config, leader, acceptors, ballot do
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
			#IO.inspect b
			#O.inspect ballot
			IO.puts "Scount receive p1b from Acceptors"

			if b == ballot do
				#IO.puts "------a,b,r,pvalues,waitfor shown as below"
				pvalues = MapSet.union(pvalues,r)
				waitfor = MapSet.delete(waitfor,a)
				#IO.inspect a
				#IO.inspect b
				#IO.inspect r
				#IO.inspect pvalues
				#IO.inspect waitfor
				if 2* MapSet.size(waitfor) < length(acceptors) do
					IO.puts "Scout sent adopted to leader"
					send leader, {:adopted, b, pvalues}
					exit(:normal)
				else
					IO.puts "Scout recursive"
		        	next config, waitfor, pvalues, ballot, leader, acceptors
	      		end
			else
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