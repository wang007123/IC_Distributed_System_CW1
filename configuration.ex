# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)

defmodule Configuration do

def node_id(config, node_type, node_num \\ "") do
  Map.merge config,
  %{
    node_type:     node_type,
    node_num:      node_num,
    node_name:     "#{node_type}#{node_num}",
    node_location: Util.node_string(),
  }
end

# -----------------------------------------------------------------------------

def params :default do
  %{
  max_requests: 1000,		# max requests each client will make
  client_sleep: 2,		# time (ms) to sleep before sending new request
  client_stop:  60_000,		# time (ms) to stop sending further requests
  client_send:	:broadcast,	# :round_robin, :quorum or :broadcast

  n_accounts:   100,		# number of active bank accounts
  max_amount:   1_000,		# max amount moved between accounts
  print_after:  1_000,		# print transaction log summary every print_after msecs

  crash_server: %{},
  window:  5, # slot
  debug: 0,
  }
end

# -----------------------------------------------------------------------------

def params :faster do
  config = params :default	# settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    debug: 1,
  }
end

# -----------------------------------------------------------------------------

def params :debug1 do		# same as :default with debug_level: 1
  config = params :default
 _config = Map.put config, :debug_level, 1
end

def params :debug3 do		# same as :default with debug_level: 3
  config = params :default
 _config = Map.put config, :debug_level, 3
end

# ADD YOUR OWN PARAMETER FUNCTIONS HERE default = 5
#WINDOW = 1 # slot

end # module ----------------------------------------------------------------

