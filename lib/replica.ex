# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)
defmodule Replica do

  def start config, database do
    receive do
      {:BIND, leaders} ->
        if config.debug == 1, do:
          IO.puts "Replica created"
        next config, 1, 1, MapSet.new, %{}, %{}, leaders, database
    end
  end


  defp next config, s_in, s_out, request_mapset, proposals_map, decisions_map, leaders, database do
    {proposals_map,decisions_map, s_out, request_mapset} =
    receive do
      #replica receives client request
      {:CLIENT_REQUEST, command} ->
        request_mapset = MapSet.put(request_mapset, command)
        #IO.puts "------"
        #IO.inspect request_mapset
        #IO.inspect MapSet.size(request_mapset)
        send config.monitor, { :CLIENT_REQUEST, config.node_num }
        {proposals_map, decisions_map, s_out, request_mapset}
      #replica receives decision 
      {:decision, slot_num, command} ->
        if config.debug == 1, do:
          IO.puts "replica received decision from commander"
        decisions_map = Map.put(decisions_map, slot_num, command)
        {request_mapset, proposals_map,s_out } = while_loop config, decisions_map, s_out, proposals_map, request_mapset, database
        {proposals_map, decisions_map, s_out, request_mapset} 
      _ -> 
        IO.puts "!Replica-next function received unexpected msg"
    end #end receuve
    #IO.inspect MapSet.size(request_mapset)
    ##IO.puts "cheking before Replica_propose"
    #IO.inspect request_mapset
    {s_in, request_mapset, proposals_map} = propose config, s_in, s_out, request_mapset, decisions_map, proposals_map, leaders
    next config, s_in, s_out, request_mapset, proposals_map, decisions_map, leaders, database
  end #end defp

  defp perform config, decisions_map, command, s_out, database do
    { client, cid, transaction } = command
    executed = Map.to_list(decisions_map)
    executed = Enum.filter(executed, fn({ s, _ }) -> s < s_out end)
    executed = Enum.map(executed, fn({ _, cmd }) -> cmd end)
    executed = Enum.member?(executed, command)
    if !executed do
      #IO.puts "Replica_perform: perform a new command"
      if config.debug == 1 do
        IO.puts "Replica_perform: perform a new command"
        IO.inspect transaction
      end
      send database, { :EXECUTE, transaction }
      send client, {:CLIENT_REPLY, cid, transaction}
      s_out + 1
    else
      #IO.puts "Replica_perform: the command did performed before"
      if config.debug == 1, do:
        IO.puts "Replica_perform: the command did performed before"
      s_out + 1
    end #end if
  end #defp

  # keep recursive until commands in decisions_map have been all deleted
  defp while_loop config, decisions_map, s_out, proposals_map, request_mapset, database do
    # {s_out, c} in decision, :decision is MapSet,
    # check the key(s_out) and get the command
    if config.debug == 1, do:
      IO.puts "replica_while_loop comparing decisions with #{s_out}"
    # delete 
    if Map.has_key?(decisions_map, s_out) do
      command_dec = decisions_map[s_out]
      {request_mapset, proposals_map} = 
      if !Map.has_key?(proposals_map, s_out) do
        {request_mapset, proposals_map}
      else
        command_prop = proposals_map[s_out]
        proposals_map = Map.delete(proposals_map, s_out)
        request_mapset = 
          if command_dec == command_prop do
            request_mapset 
          else
            MapSet.put(request_mapset, command_prop)
          end
        {request_mapset, proposals_map} 
      end
      if config.debug == 1, do:
        IO.puts "replica_while_loop_decisions get the command"
      s_out = perform config, decisions_map, command_dec, s_out, database
      while_loop config, decisions_map, s_out, proposals_map, request_mapset, database
    else
        if config.debug == 1, do:
          IO.puts "replica_while_loop decisions_map don't have the command & wait"
        {request_mapset, proposals_map, s_out}
    end #end if
  end #endf defp

 #propose function - transfer request_mapset from the set request_mapset to proposals_map
 #return {s_in, request_mapset, proposals_map}
  defp propose config, s_in, s_out, request_mapset, decisions_map, proposals_map, leaders do
    if (s_in < (s_out + config.window)) and (MapSet.size(request_mapset) > 0) do
      if config.debug == 1, do:
        IO.puts "replica handling a request ----------------"
      #IO.inspect request_mapset
      tmp_list = MapSet.to_list(request_mapset)
      command = hd(tmp_list)
      #∃op:⟨s_in−𝚆𝙸𝙽𝙳𝙾𝚆,⟨⋅,⋅,op⟩⟩∈decision
      # leaders:=op.leaders;
      # ⟨⋅,⋅,op⟩ is equal to command, However,
      #if (MapSet.size(request_mapset) > 1) do
      #  {_,_,c} = decisions_map[1]
      #  IO.inspect c
      #end
      # e.g c is {:MOVE, 555, 29, 32}, which is trasaction. no leaders parameter inside
      # so commented this part.

      { request_mapset, proposals_map } =
      if !Map.has_key?(decisions_map, s_in) do
        request_mapset = MapSet.delete(request_mapset, command)
        proposals_map = Map.put(proposals_map, s_in, command)
        #replica send broadcast msg to all leaders
        if config.debug == 1, do:
          IO.puts "replica broadcast command to all leader"
        for leader <- leaders do
          send leader, {:propose, s_in, command}
        end
        { request_mapset, proposals_map }
      else
        { request_mapset, proposals_map }
      end
      # for loop, recursive  
      s_in = s_in + 1
      propose config, s_in, s_out, request_mapset, decisions_map, proposals_map, leaders
    else
      {s_in, request_mapset, proposals_map}
    end
  end #end defp





end #end module