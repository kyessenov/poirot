open models/basicNoStep

-- module Blogger
one sig Blogger extends Module {
	Blogger__protects : Token set -> lone UID,
	Blogger__owns : UID set -> lone PostID,
	Blogger__posts : PostID set -> lone String,
}{
	all o : this.receives[Blogger__ReadPost] | o.(Blogger__ReadPost <: Blogger__ReadPost__ret) = Blogger__posts[o.(Blogger__ReadPost <: Blogger__ReadPost__postID)]
	all o : this.receives[Blogger__CreatePost] | o.(Blogger__CreatePost <: Blogger__CreatePost__content)
	this.initAccess in NonCriticalData + Token.Blogger__protects + Blogger__protects.UID + UID.Blogger__owns + Blogger__owns.PostID + PostID.Blogger__posts + Blogger__posts.String
}

-- module BloggerUser
one sig BloggerUser extends Module {
}{
	this.initAccess in NonCriticalData
}


-- operation Blogger__ReadPost
sig Blogger__ReadPost extends Op {
	Blogger__ReadPost__postID : one PostID,
	Blogger__ReadPost__token : one Token,
	Blogger__ReadPost__ret : set String,
}{
	args in Blogger__ReadPost__postID + Blogger__ReadPost__token
	ret in Blogger__ReadPost__ret
	sender in BloggerUser
	receiver in Blogger
}

-- operation Blogger__CreatePost
sig Blogger__CreatePost extends Op {
	Blogger__CreatePost__content : set String,
	Blogger__CreatePost__token : one Token,
}{
	args in Blogger__CreatePost__content + Blogger__CreatePost__token
	no ret
	sender in BloggerUser
	receiver in Blogger
}

-- datatype declarations
sig String extends Data {
}{
	this not in (UID + Token + PostID) implies no fields
}
sig UID extends String {
}{
	no fields
}
sig Token extends String {
}{
	no fields
}
sig PostID extends String {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

run SanityCheck {
  some Blogger__ReadPost & SuccessOp
  some Blogger__CreatePost & SuccessOp
} for 2 but 4 Data, 2 Op, 2 Module


check Confidentiality {
  Confidentiality
} for 2 but 4 Data, 2 Op, 2 Module


-- check who can create CriticalData
check Integrity {
  Integrity
} for 2 but 4 Data, 2 Op, 2 Module
