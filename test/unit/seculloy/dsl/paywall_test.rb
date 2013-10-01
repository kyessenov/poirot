require 'test_helper'

require 'seculloy/case_studies/paywall/http'
require 'seculloy/case_studies/paywall/paywall'
require 'seculloy/case_studies/paywall/referer'

require 'sdsl/myutils'


class PaywallTest < Test::Unit::TestCase
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions

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
    puts ref
  end
end
