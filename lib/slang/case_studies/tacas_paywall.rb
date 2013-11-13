require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view(:TacasPaywall) {
  critical data Page; data Link
  
  trusted component NYTimes [
    articles: Link ** Page, 
    limit: Integer
  ] {
    creates Page
  
    operation GetPage[link: Link, currCounter: Integer] {
      guard    { currCounter < limit }
      response { Client::SendPage[articles[link], currCounter + 1] }}}

  trusted component Client [
    counter: (dynamic Integer)
  ] {
    operation SendPage[page: Page, newCounter: Integer] {
      effects  { self.counter = newCounter }
      response { Reader::Display[page] }}

    operation SelectLink[link: Link] {
      response { NYTimes::GetPage[link, counter] }}}

  component Reader {
    operation Display[page: Page]
    response { Client::SelectLink }}}
