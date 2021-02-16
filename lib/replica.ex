defmodule Replica do

  def start config, database do
    receive do
      {:BIND, leaders} ->
        IO.puts "Replica created"
        next config, 1, 1, MapSet.new, MapSet.new, MapSet.new, leaders, database
    end
  end

  # confused about initia (database..)
  def next config, slot_in, slot_out, requests, proposals, decisions, leaders, database do
    receive do
      #replica receives :request
      {:CLIENT_REQUEST, command} ->
        #IO.puts "Replica received request from client"
        requests = MapSet.put(requests, command)
        send config.monitor, { :CLIENT_REQUEST, config.node_num }
        { slot_out, (MapSet.put requests, command), proposals, decisions }
      #replica receives :decision
      {:decision, slot_num, command} ->
        IO.puts "replica received decision from commander"
        decisions = MapSet.put(decisions, {slot_num, command})
        send config.monitor, { :COMMANDER_FINISHED, config.node_num }
        {slot_out, requests, proposals} = while config, decisions, slot_out, proposals, requests, database
      _ -> IO.puts "!Replica-next function received unexpected msg"

      {slot_out, requests, proposals} 
    end
    {slot_in, requests, proposals} = propose config, slot_in, slot_out, requests, decisions, proposals, leaders

    next config, slot_in, slot_out, requests, proposals, decisions, leaders, database
  end

  # while function used when receive decisions message
  defp while config, decisions, slot_out, proposals, requests, database do
    # {slot_out, c} in decision, :decision is MapSet,
    # check the key(slot_out) and get the command
    if Map.has_key?(decisions, slot_out) do
      command_first = decisions[slot_out]
      {requests, proposals} = 
      if Map.has_key?(proposals, slot_out) do
        proposals = Map.delete(proposals, slot_out)
        command_sec = proposals[slot_out]
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
      IO.puts "replica_while_decisions get the command"
      slot_out = perform config, decisions, command_first, slot_out, database
      while config, decisions, slot_out, proposals, requests, database
    else
        IO.puts "replica_while_decisions don't have the command"
        {slot_out, requests, proposals}
    end

  end


  defp perform config, decisions, command, slot_out, database do
    #command = {client, cid, op}
    command = decisions[slot_out]
    {_client, _cid, op} = command

    #may have problem
    exist = Enum.reduce 1..(slot_out-1), false, fn s, acc ->
            acc or ((Map.has_key? decisions, s) and decisions[s] === command)
          end   

    if (exist == true)  do
      IO.puts "perform test passed"
      slot_out + 1
    else
      IO.puts "perform test failed"
      { client, cid, transaction } = command

      IO.inspect (IEx.Info.info(transaction))
      send database, { :EXECUTE, transaction }
      slot_out = slot_out + 1
      send client, {:CLIENT_REPLY, cid, transaction}
      slot_out
    end
  end


 #propose function - transfer requests from the set requests to proposals
 #{slot_in, requests, proposals}
  defp propose config, slot_in, slot_out, requests, decisions, proposals, leaders do
    if (slot_in < slot_out + config.window) and (MapSet.size(requests) > 0) do
      command = Map.to_list(requests)
      {client, cid, op} = command
      if Map.has_key?(decisions, slot_in - config.window) do
        leaders = op.leaders
      end

      { requests, proposals } =
      if !Map.has_key?(decisions, slot_in) do
        requests = Map.delete(requests, command)
        proposals = MapSet.put(proposals, {slot_in, command})
        #replica send broadcast msg to all leaders
        for leader <- leaders do
          send leader, {:propose, slot_in, command}
        end
        { requests, proposals }
      else
        { requests, proposals }
      end
      slot_in = slot_in + 1
      # recursive function
      propose config, slot_in, slot_out, requests, decisions, proposals, leaders
    else
      {slot_in, requests, proposals}
    end
  end


end
