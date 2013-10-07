require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :NYT do
  data ArticleID, Article
  abstract data Number
  data BelowLimit extends Number
  data AboveLimit extends Number
  
  trusted NYTimes [
    articles: ArticleID ** Article
  ] do
    creates Article

    operation GetArticle[articleID: ArticleID, numAccessed: Number] do
      guard { numAccessed.in?(BelowLimit) }
      sends { NYTUser::SendArticle[articles[articleID]] }
    end
  end

  trusted NYTUser do
    operation SendArticle[article: Article]
    sends { NYTimes::GetArticle }
  end
end

Slang::Dsl.view :WP do
  data News

  trusted WPost [
    news: (set News)
  ] do

    operation GetLatestNews[] do
      sends { 
        ns = News.some {|n| n.in? news}
        WPUser::SendArticle[ns] 
      }
    end
  end

  trusted WPUser do
    operation SendArticle[n: News]
    sends { WPost::GetLatestNews }
  end
end
