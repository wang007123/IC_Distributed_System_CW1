defmodule Replica do

  def start config do
    receive do
      {:bind, leaders, initial_state} ->
        next config initial_state, 1, 1, MapSet.new, MapSet.new, MapSet.new, leaders
    end
  end

  # confused about initial_state (database..)
  def next config, state, slot_in, slot_out, requests, proposals, decisions, leaders do
    receive do
      #replica receives :request
      {:request, command} ->
        requests = MapSet.put(requests, command)
      #replica receives :decision
      {:decision, slot_num, command} ->
        decisions = MapSet.put(decisions, {slot_num, command})
        {slot_out, requests, proposals} = while config, state, decisions, slot_out, proposals, requests
    end
    {slot_in, requests, proposals} = propose config, slot_in, slot_out, requests, decisions, proposals, leaders

    next config, state, slot_in, slot_out, requests, proposals, decisions, leaders
  end

  # while function used when receive decisions message
  defp while config, state, decisions, slot_out, proposals, requests do
    # {slot_out, c} in decision, :decision is MapSet,
    # check the key(slot_out) and get the command
    if Map.has_Key?(decisions, slot_out) do
      command_first = decisions[slot_out]
      if Map.has_key?(proposals, slot_out) do
        proposals = Map.delete(proposals, slot_out)
        command_sec = proposals[slot_out]
        if command_first != command_sec do
          requests = Map.put(requests, command_sec)
        else
          requests = requests
        end
      else
        proposals = proposals
      end
      slot_out = perform decisions, command_first, slot_out, state
      while config, state, decisions, slot_out, proposals, requests

      else
      {slot_out, requests, proposals}
    end

  end


  defp perform decisions, command, slot_out, state do
    #command = {client, cid, op}
    command = decisions[slot_out]
    {client, cid, op} = command

    #may have problem
    exist = Enum.reduce((slot_out - 1)..1, fn x -> Map.has_key?(decisions, x) end)
    if (exist == true) or isreconfig(op) do
      slot_out = slot_out + 1
    else
      result = #?
        state = #?
          slot_out = slot_out + 1
      send client, {:response, cid, result}
    end
  end


 #propose function - transfer requests from the set requests to proposals
 #{slot_in, requests, proposals}
  defp propose config, slot_in, slot_out, requests, decisions, proposals, leaders do
    if (slot_in < slot_out + config.WINDOW) and (MapSet.size(requests) > 0) do
      command = Map.to_list(requests)
      {client, cid, op} = command
      if Map.has_key?(decisions, slot_in - config.WINDOW) and isreconfig(op) do
        leaders = op.leaders
      end

      if !Map.has_key?(decisions, slot_in) do
        requests = Map.delete(requests, command)
        proposals = MapSet.put(proposals, {slot_in, command})
        for leader <- leaders do
          send leader, {:propose, slot_in, command}
        end
        requests = requests
        proposals = proposals
      end
      slot_in = slot_in + 1

      propose config, slot_in, slot_out, requests, decisions, proposals, leaders
    else
      {slot_in, requests, proposals}
    end
  end

  defp isreconfig op do
    match?({_, _, {:reconfig, _}}, op)
  end

end
