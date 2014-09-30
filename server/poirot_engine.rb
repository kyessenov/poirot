$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../server', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../alloy_ruby/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../sdg_utils/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../arby/lib', __FILE__)

require 'sdsl/myutils'
require 'pry'
require 'inst_parser'

MAX_TRACE_LENGTH = 7

SLANG_PREFIX =
"
require 'slang/slang_dsl'

include Slang::Dsl
Component = Slang::Model::Module
AllData = Slang::Model::Data

Slang::Dsl.view :PoirotModel do
"

SLANG_SUFFIX =
"
  component EvilServer {
    typeOf HttpServer
    op EvilHttpReq[in: (set AllData), ret: AllData] 
  }

  component EvilClient {
    typeOf Browser
  }
end
"

DEFAULT_MODEL_NAME = "PoirotModel"
ALLOY_JAR_NAME = "server/generated/alloy/CmdAlloy.jar"
DEFAULT_ALLOY_INST = "server/generated/alloy/out.xml"
JNI_PATH = "server/generated/alloy/libjni"

def pad_model model
  SLANG_PREFIX + model + SLANG_SUFFIX  
end

def run_alloy(alloy_file, cmd)
  puts "%%%%%%%%%%%%%%%"
  puts "Running alloy"
  java_str = "java -jar -Djava.library.path=#{JNI_PATH} #{ALLOY_JAR_NAME} #{alloy_file} #{cmd}"  
  if (cmd == "SanityCheck")
    system java_str
  else 
    system "#{java_str} #{MAX_TRACE_LENGTH}"
  end
  system "mv out.xml #{DEFAULT_ALLOY_INST}"
  puts "%%%%%%%%%%%%%%%"
end

def run_poirot(cmd, fname, model_name=DEFAULT_MODEL_NAME)
  puts "##########"
  fail "Cannt load `#{fname}'" unless load fname
  view = (eval(model_name) rescue nil)

  fail "Model not found: #{model_name}" unless view
  out_file ||= "server/generated/alloy/#{model_name.downcase}.als"
  dot_out_file ||= "server/generated/alloy/#{model_name.downcase}.dot"

  # sdsl_view = view.meta.to_sdsl
  sdsl_view = view.meta.to_poirot_sdsl
  drawView(sdsl_view, dot_out_file)
  dumpAlloy(sdsl_view, out_file)
  
  puts "Alloy file saved in #{out_file}"
  puts "##########"
  
  run_alloy(out_file, cmd)
  parse_alloy_instance DEFAULT_ALLOY_INST
end

