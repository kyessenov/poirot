require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :TacasPaywall do
  critical data Page
  data Link
  
  trusted component NYTimes [
    articles: Link ** Page, 
    limit: Integer
  ] do
    creates Page
  
    operation GetPage [link: Link, currCounter: Integer] do
      guard    { currCounter < limit }
      response { Client::SendPage[articles[link], currCounter + 1] }
    end
  end

  trusted component Client [
    counter: (dynamic Integer)
  ] do

    operation SendPage[page: Page, newCounter: Integer] do 
      effects  { self.counter = newCounter }
      response { Reader::Display[page] }
      # response {
      #   self.counter = newCounter
      #   Reader::Display[page] 
      # }
    end

    operation SelectLink[link: Link] do
      response { NYTimes::GetPage[link, counter] }
    end
  end

  component Reader do
    operation Display[page: Page]
    response { Client::SelectLink }
  end
end
