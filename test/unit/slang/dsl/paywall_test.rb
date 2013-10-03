require 'test_helper'

require 'slang/model/refinement'

require 'slang/case_studies/paywall/http'
require 'slang/case_studies/paywall/paywall'
require 'slang/case_studies/paywall/referer'

require 'sdsl/myutils'


class PaywallTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions

  include Seculloy::Model

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
             NYTimes::GetArticle => Server::SendReq,
             Browser::SendArticle => Client::SendResp
           }, 
           :invokes => {
             NYTimes::GetArticle => Server::SendReq,
             Browser::SendArticle => Client::SendResp
           },
           :data => {
             Article => Str,
             ArticleID => Str,
             Number => Str
           }
          ]
  end

  def test_xxx
    r = Refinement.define(Paywall, HTTP) do
      mod_map NYTimes => Server do
        op_map GetArticle => SendReq
      end

      mod_map Browser => Client do
        op_map SendArticle => SendResp
      end

      data_map Article   => Str,
               ArticleID => Str,
               Number    => Str
    end
  end

end
