require 'test_helper'

require 'slang/model/refinement'

require 'slang/case_studies/http/http'
require 'slang/case_studies/paywall/paywall'
# require 'slang/case_studies/paywall/referer_interaction'

require 'sdsl/myutils'


class PaywallTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions

  include Slang::Model

  include Paywall
  include HTTP

  def view() Paywall.meta end

  def test1
    assert view
  end

  def test2
    ref = [
           :module => {
             NYTimes => Server,
             Browser => Client
           },
           :exports => {
             NYTimes::GetLink => Server::SendReq,
             Client::SendPage => Browser::SendResp
           }, 
           :invokes => {
             NYTimes::GetLink => Server::SendReq,
             Client::SendPage => Browser::SendResp
           },
           :data => {
             Page => HTML
           }
          ]
  end

  def test_xxx
    r = Refinement.define(Paywall, HTTP) do
      mod_map NYTimes => Server do
        op_map GetLink => SendReq
      end

      mod_map Client => Browser do
        op_map SendPage => SendResp
      end

      data_map Page => HTML
    end
  end

end
