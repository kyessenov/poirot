require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Blogger do
  data String, UID, Passwd, Token, PostID
  
  trusted component Blogger [
    passwds: UID ** Passwd,
    tokens: UID ** Token,
    owns: UID ** PostID, 
    posts: PostID ** String[]
  ] do
    op CreatePost[content: String[], blogToken: Token] {
      guard { blogToken } 
    }
    op ReadPost[postID: PostID, blogToken: Token, ret: String[]] {
      guard { currCounter < limit }
    }
  end

  component BloggerUser {
    invokes { Blogger::CreatePost } 
    invokes { Blogger::ReadPost }
  }
end
