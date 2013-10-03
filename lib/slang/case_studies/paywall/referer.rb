require 'slang/slang_dsl'

include Seculloy::Dsl

Seculloy::Dsl.view :PaywallReferer do

  data Article
  data ArticleID
  abstract data Referer
  data GoogleReferer < Referer

  critical Article

  trusted NYTimes [
    articles: ArticleID ** Article
  ] do
    creates Article

    operation GetArticle[articleID: ArticleID, referer: Referer] do
      guard { referer.in? GoogleReferer }
      sends { Browser::SendArticle[articles[articleID]] }
    end
  end

  trusted Browser do
    operation SendArticle[article: Article] do end
    operation SelectArticle[articleID: ArticleID] do
      sends { NYTimes::GetArticle[articleID] }
    end
    operation SearchArticle[articleID: ArticleID] do
      sends { Google::Search[articleID] }
    end
    operation SendSearchResult[articleID: ArticleID, referer: Referer] do end
    
    sends { Reader::Display }
  end

  trusted Google [
    referer: GoogleReferer
  ] do
    creates GoogleReferer
    
    operation Search[articleID: ArticleID] do
      sends { Browser::SendSearchResult[articleID, referer] }
    end
  end

  mod Reader do
    operation Display[article: Article] do end
    sends { Browser::SelectArticle }
  end

end
