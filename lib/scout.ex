defmodule Scout do

def start config, leader, acceptors, ballot do
	for acceptor <- acceptors do
		send acceptor, {:p1a, self(), ballot}
	end
	send config.monitor, { :SCOUT_SPAWNED, config.node_num }
	next config, MapSet.new(acceptors), MapSet.new, ballot, leader, acceptors

end

defp next config, waitfor, pvalues, ballot, leader, acceptors do
	receive do
		{:p1b, acceptors, ballot_,r} ->
			IO.puts "receive p1b"
			if ballot_ == ballot do
				pvalues = MapSet.union(pvalues,r)
				waitfor = MapSet.delete(waitfor,r)
				#IO.inspect (IEx.Info.info(acceptors))
				# IT SHOULD BE .... COMMENT FOR DEBUG
				IO.puts "waitfor size is #{MapSet.size(waitfor)}"
				IO.puts "acceptors length is #{length(acceptors)}"
				if 2 * MapSet.size(waitfor) < length(acceptors) do
				#if !(2 * MapSet.size(waitfor)) do
					send leader, {:adopted, ballot, pvalues}
					exit(:normal)
				else
			        next config, waitfor, pvalues, ballot, leader, acceptors
		      	end
			else
				send leader, {:preempted, ballot_}
            	send config.monitor, { :SCOUT_FINISHED, config.node_num }
				exit(:normal)
			end
		_ -> IO.puts "!Scout-next function received unexpected msg"
	end
end

end #end defmodule