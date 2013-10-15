require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Paywall do

  abstract data Page
  critical data Article < Page
  data Link

  trusted NYTimes [
    articles: Link ** Article,
    limit: Int
  ] do
    creates Article

    operation GetLink[link: Link, numAccessed: Int] do
      guard { numAccessed < limit }
      sends { Client::SendPage[articles[link], numAccessed + 1] }
    end
  end

  trusted Client [
    numAccessed: (dynamic Int)
  ] do

    operation SendPage[page: Page, newCounter: Int] do 
      effects { self.numAccessed = newCounter }
      sends { Reader::Display[page] }
    end

    operation SelectLink[link: Link] do
      sends { NYTimes::GetLink[link, numAccessed] }
    end
  end

  mod Reader do
    operation Display[page: Page]
    sends { Client::SelectLink }
  end

end

