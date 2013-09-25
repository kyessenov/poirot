require 'seculloy/seculloy_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :Paywall do

  data Article
  data ArticleID
  abstract data Number
  data BelowLimit < Number
  data AboveLimit < Number

  critical Article

  trusted NYTimes [
    articles: ArticleID ** Article
  ] do
    creates Article

    operation GetArticle[articleID: ArticleID, numAccessed: Number] do
      guard { numAccessed.in?(BelowLimit) }
      sends { Browser::SendArticle[articles[articleID]] }
    end
  end

  trusted Browser [
    numAccessed: Number
  ] do

    operation SendArticle[article: Article] do end

    operation SelectArticle[articleID: ArticleID] do
      sends { NYTimes::GetArticle[articleID, numAccessed] }
    end
    
    sends { Reader::Display }

  end

  mod Reader do
    operation Display[article: Article] do end
    sends { Browser::SelectArticle }
  end

end
