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

def params :custom_debug do
  config = params :default	# settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    debug: 1,
  }
end

def params :test_case_2_2 do
  config = params :default  # settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    window: 100,
  }
end

def params :test_case_4 do
  config = params :default  # settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    crash_server: %{1 => 5000}
  }
end
def params :test_case_5 do
  config = params :default  # settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    crash_server: %{1 => 5000, 2 => 5000}
  }
end
def params :test_case_6_1 do
  config = params :default  # settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    max_requests: 100,
  }
end

def params :test_case_6_2 do
  config = params :default  # settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    window: 5000,
  }
end

def params :test_case_7 do
  config = params :default  # settings for faster throughput
 _config = Map.merge config,
  %{
    # ADD YOUR OWN PARAMETERS HERE
    window: 100,
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

