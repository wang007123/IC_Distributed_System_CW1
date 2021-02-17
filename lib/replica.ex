defmodule Replica do

  def start config, database do
    receive do
      {:BIND, leaders} ->
        if config.debug == 1, do:
          IO.puts "Replica created"
        next config, 1, 1, MapSet.new, %{}, %{}, leaders, database
    end
  end


  defp next config, slot_in, slot_out, requests, proposals, decisions, leaders, database do
    {slot_out, requests, proposals,decisions} =
    receive do
      #replica receives :request
      {:CLIENT_REQUEST, command} ->
        if config.debug == 1, do:
          IO.puts "Replica received request from client"
        requests = MapSet.put(requests, command)
        #IO.puts "------"
        #IO.inspect requests
        #IO.inspect MapSet.size(requests)
        send config.monitor, { :CLIENT_REQUEST, config.node_num }
        {slot_out, requests, proposals, decisions}
      #replica receives :decision 
      {:decision, slot_num, command} ->
        if config.debug == 1 do
          IO.puts "replica received decision from commander"
          IO.puts "adding slot_num #{slot_num} to decisions"
        end
        decisions = Map.put(decisions, slot_num, command)
        {slot_out, requests, proposals} = while config, decisions, slot_out, proposals, requests, database
        {slot_out, requests, proposals, decisions} 
      _ -> 
        IO.puts "!Replica-next function received unexpected msg"
    end #end receuve
    #IO.inspect MapSet.size(requests)
    ##IO.puts "cheking before Replica_propose"
    #IO.inspect requests
    {slot_in, requests, proposals} = propose config, slot_in, slot_out, requests, decisions, proposals, leaders
    next config, slot_in, slot_out, requests, proposals, decisions, leaders, database
  end

 #propose function - transfer requests from the set requests to proposals
 #{slot_in, requests, proposals}
  defp propose config, slot_in, slot_out, requests, decisions, proposals, leaders do
    if (slot_in < (slot_out + config.window)) and (MapSet.size(requests) > 0) do
      if config.debug == 1, do:
        IO.puts "replica handling a request ----------------"
      #IO.inspect requests
      command = hd(MapSet.to_list(requests))
      #IO.inspect command
      #{client, cid, op} = command
      #if Map.has_key?(decisions, slot_in - config.window) do
      #  leaders = leaders
      #end
      { requests, proposals } =
      if !Map.has_key?(decisions, slot_in) do
        #IO.inspect requests
        requests = MapSet.delete(requests, command)
        ##IO.puts "after delteing------------------------=="
        #IO.inspect requests
        proposals = Map.put(proposals, slot_in, command)
        #replica send broadcast msg to all leaders
        if config.debug == 1, do:
          IO.puts "replica broadcast command to all leader"
        for leader <- leaders do
          send leader, {:propose, slot_in, command}
        end
        { requests, proposals }
      else
        { requests, proposals }
      end
      slot_in = slot_in + 1
      # for loop
      propose config, slot_in, slot_out, requests, decisions, proposals, leaders
    else
      {slot_in, requests, proposals}
    end
  end #end defp

  # while function used when receive decisions message
  defp while config, decisions, slot_out, proposals, requests, database do
    # {slot_out, c} in decision, :decision is MapSet,
    # check the key(slot_out) and get the command
    if config.debug == 1, do:
      IO.puts "replica_while comparing decisions with #{slot_out}"
    if Map.has_key?(decisions, slot_out) do
      command_first = decisions[slot_out]
      {requests, proposals} = 
      if Map.has_key?(proposals, slot_out) do
        command_sec = proposals[slot_out]
        proposals = Map.delete(proposals, slot_out)
        requests = 
        if command_first != command_sec do
          MapSet.put(requests, command_sec)
        else
          requests
        end
        {requests,proposals}
      else
        {requests, proposals}
      end
      if config.debug == 1, do:
        IO.puts "replica_while_decisions get the command"
      slot_out = perform config, decisions, command_first, slot_out, database
      while config, decisions, slot_out, proposals, requests, database
    else
        if config.debug == 1, do:
          IO.puts "replica_while decisions don't have the command"
        {slot_out, requests, proposals}
    end

  end


  defp perform config, decisions, command, slot_out, database do
    { client, cid, transaction } = command
    executed = Map.to_list(decisions)
    executed = Enum.filter(executed, fn({ s, _ }) -> s < slot_out end)
    executed = Enum.map(executed, fn({ _, cmd }) -> cmd end)
    executed = Enum.member?(executed, command)
    if executed do
      if config.debug == 1, do:
        IO.puts "Replica_perform: the command did performed before"
      slot_out + 1
    else
      if config.debug == 1 do
        IO.puts "Replica_perform: perform a new command"
        IO.inspect transaction
      end
      send database, { :EXECUTE, transaction }
      slot_out = slot_out + 1
      send client, {:CLIENT_REPLY, cid, transaction}
      slot_out
    end #end if
  end #defp

end #end module
