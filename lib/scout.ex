defmodule Scout do

def start config, leader, acceptors, ballot do
	send acceptors, {:p1a, self(), ballot}
	next config, acceptors, 0, ballot, leader, acceptors

end

defp next config waitfor, pvalues, ballot, leader, acceptors do
	receive do
		{:p1b, acceptors, ballot_,r} ->
			if ballot_ == ballot do
				pvalues = pvalues ++ r
				waitfor = MapSet.delete(waitfor,r)
				if MapSet.size(waitfor) < length(acceptors)/2 do
					send leader, {:adopted, ballot, pvalues}
					exit(:normal)
				end
			else
				send leader, {:preempted, ballot_}
				exit(:normal)
			end
	end
end

end #end defmodule
