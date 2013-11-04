-- area2.rb
check NoBadStudentAccess {
	no p : Profile, t : Step |
		p in Student.accesses.t and
		p.(Profile__id) != Student.Student__id
} for 1 but 8 Data, 8 Step, 7 Op

fact {
	all sid : StudentID, p : Profile, t : Step |
		sid -> p in A2Site.A2Site__profiles.t implies p.Profile__id = sid
}

