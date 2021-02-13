defmodule Commander do

def config, leader, acceptors, replicas, {b, s, c} do
	send acceptors, {:p2a, self(),{b, s, c}}
	next config, MapSet.new(acceptors), leader,acceptors, replicas, {b, s, c}
end

defp next config, waitfor, leader,acceptors, replicas, {b, s, c} do
	receive do
		{:p2b, acceptors, b_} ->
			if b_ == b do
				waitfor = MapSet.delete(waitfor, acceptors)
				if MapSet.size(waitfor) < length(acceptors)/2 do
					send replicas, {decision, s, c}
					exit(:normal)
				end
			else
				send leader, {:preempted, b_}
				exit(:normal)
			end
	end
end


end #end defmodule
