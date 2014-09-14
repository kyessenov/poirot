# Poirot
require 'sinatra'
require 'json'
require 'cgi'

get '/' do 
  'Hello world!'
end

get '/poirot' do
  send_file 'public/poirot.html'
end

post '/run' do
  
  sampleInst =  {
    :cmps => [
	{:inst => "Server0", :type => "Server", :trusted => true},
	{:inst => "Server1", :type => "Server", :trusted => false},
	{:inst => "Browser0", :type => "Browser", :trusted => true},
	{:inst => "Browser1", :type => "Browser", :trusted => false},
	{:inst => "User0", :type => "User", :trusted => true},
	{:inst => "User1", :type => "User", :trusted => false}
    ],     
    :data  => [
	{:inst => "d0", :type => "TypeA"},
	{:inst => "d1", :type => "TypeA"},
	{:inst => "d2", :type => "TypeB"},
	{:inst => "d3", :type => "TypeB"},
	{:inst => "d4", :type => "TypeC"},
	{:inst => "d5", :type => "TypeC"}
    ],
    :events  => [
	{:inst => "Op0", :type => "HTTPReq", :args => ["d0"], 
	 :ret => ["d1"], :sender => "Browser0", :receiver => "Server0"},
	{:inst => "Op1", :type => "HTTPReq", :args => ["d1", "d2"], 
	 :ret => ["d3"], :sender => "Browser1", :receiver => "Server0"},
	{:inst => "Op2", :type => "VisitPage", :args => [], 
	 :ret => ["d4"], :sender => "User0", :receiver => "Browser0"},
	{:inst => "Op3", :type => "VisitPage", :args => ["d3"], 
	 :ret => [], :sender => "User1", :receiver => "Browser1"},
	{:inst => "Op4", :type => "HTTPReq", :args => ["d2"], 
	 :ret => ["d3"], :sender => "Browser1", :receiver => "Server1"}
    ],
    :database  => [
    	{:UserID => "UserID0", :Key => "Key2"}, 
	{:UserID => "UserID1", :Key => "Key1"}
    ]
  }

  request.body.rewind
  data = request.body.read
  model = (CGI::unescape(data))
  model = model[("model=".size)..(model.size - 1)]    
  puts "******"
  puts sampleInst.to_json
  File.open("generated/model.rb", 'w') {|f| f.write(model) }
  puts "******"
  sampleInst.to_json
end
