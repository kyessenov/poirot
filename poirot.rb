# Poirot
require 'sinatra'
require 'json'
require 'cgi'
require_relative 'server/poirot_engine'

DEFAULT_INST_PATH = "server/generated/poirot/inst.rb"
DEFAULT_MODEL_PATH = "server/generated/poirot/poirotmodel.rb"

set :bind, '0.0.0.0'

get '/' do 
  'Hello world!'
end

get '/poirot' do
  send_file 'public/poirot.html'
end

def chop_model model
  model[("model=".size)..(model.size - 1)]
end

post '/run' do
  request.body.rewind
  data = request.body.read
  model = (CGI::unescape(data))
  model = chop_model(model)   
  run_model(model, "SanityCheck")  
end

post '/analyze' do
  request.body.rewind
  data = request.body.read
  model = (CGI::unescape(data))
  model = chop_model(model)
  run_model(model, "myPolicy")    #TODO: Fix it
end

def run_model(model, cmd)
  puts "******"
  puts model
  f = File.open(DEFAULT_MODEL_PATH, 'w')
  f.write(pad_model(model))
  f.close
  puts "******"

  fork do
    f = File.open(DEFAULT_INST_PATH, 'w')
    inst = run_poirot(cmd, DEFAULT_MODEL_PATH)
    f.write(inst.to_json)
    f.close
  end
  Process.wait

  puts "trying to read"
  f = File.open(DEFAULT_INST_PATH, 'r')  
  inst_json = f.readlines[0]
  f.close
  puts inst_json
  inst_json

end

# sampleInst =  {
#   :cmps => [
#             {:inst => "Server0", :type => "Server", :trusted => true},
#             {:inst => "Server1", :type => "Server", :trusted => false},
#             {:inst => "Browser0", :type => "Browser", :trusted => true},
#             {:inst => "Browser1", :type => "Browser", :trusted => false},
#             {:inst => "User0", :type => "User", :trusted => true},
#             {:inst => "User1", :type => "User", :trusted => false}
#            ],     
#   :data  => [
#              {:inst => "d0", :type => "TypeA"},
#              {:inst => "d1", :type => "TypeA"},
#              {:inst => "d2", :type => "TypeB"},
#              {:inst => "d3", :type => "TypeB"},
#              {:inst => "d4", :type => "TypeC"},
#              {:inst => "d5", :type => "TypeC"}
#             ],
#   :events  => [
#                {:inst => "Op0", :type => "HTTPReq", :args => ["d0"], 
#                  :ret => ["d1"], :sender => "Browser0", :receiver => "Server0"},
#                {:inst => "Op1", :type => "HTTPReq", :args => ["d1", "d2"], 
#                  :ret => ["d3"], :sender => "Browser1", :receiver => "Server0"},
#                {:inst => "Op2", :type => "VisitPage", :args => [], 
#                  :ret => ["d4"], :sender => "User0", :receiver => "Browser0"},
#                {:inst => "Op3", :type => "VisitPage", :args => ["d3"], 
#                  :ret => [], :sender => "User1", :receiver => "Browser1"},
#                {:inst => "Op4", :type => "HTTPReq", :args => ["d2"], 
#                  :ret => ["d3"], :sender => "Browser1", :receiver => "Server1"}
#               ],
#   :database  => [
#                  {:UserID => "UserID0", :Key => "Key2"}, 
#                  {:UserID => "UserID1", :Key => "Key1"}
#                 ]
# }
