require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :Blogger do
  data String
  data UID, Token, PostID < String

  component Blogger [
    protects: Token ** UID,
    owns: UID ** PostID, 
    posts: PostID ** (set String)
  ] do
    op ReadPost[postID: PostID, token: Token, ret: (set String)] {
      guard { 
        protects[token] == owns.(postID)
        ret == posts[postID]
      }
    }
    op CreatePost[content: (set String), token: Token] {
      guard {
        uid = protects[token]        
        newPostID = PostID.select{|p| p.not_in? owns[uid]}
        posts[newPostID] = content
      }
    }
  end

  component BloggerUser do
    invokes { Blogger::CreatePost } 
    invokes { Blogger::ReadPost }
  end
end
