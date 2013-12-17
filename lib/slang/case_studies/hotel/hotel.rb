require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :HotelLocking do

#  data Key[nxt: Key]
  data Key[nxt: Int]
  data RoomNumber
  data GuestID

  trusted FrontDesk [
    lastKey: (dynamic RoomNumber ** Key),
    occupant: (dynamic RoomNumber ** GuestID)
  ] do
    creates Key
    op Checkin[id: GuestID, rm: RoomNumber, ret: Key] do
      guard {
        no self.occupant[rm]
        ret == self.lastKey[rm].nxt
      }
      effects {
        self.lastKey = self.lastKey + (rm ** ret)
        self.occupant = self.occupant + (rm ** id)
      }
    end
    op Checkout[id: GuestID] do
      guard {
#        some occupant.id
        occupant.some {|r, i| i == id}
      }
      effects {
        no occupant.id
      }
    end
  end

  trusted Room [
    num: RoomNumber,
    currentKey: (dynamic Key)
  ] do
    assumption {
      currentKey.in? keys
    }
    op Entry[k: Key] do
      guard {
        (k == self.currentKey) or (k == self.currentKey.nxt)
      }
      effects {
        self.currentKey = self.currentKey.nxt
      }
    end
  end

  trusted GoodGuest [
    id: GuestID
  ] do
    sends { FrontDesk::Checkin }
    sends { FrontDesk::Checkout }
    sends { Room::Entry }
  end

  mod BadGuest [
    id: GuestID
  ] do
    sends { FrontDesk::Checkin }
    sends { FrontDesk::Checkout }
    sends { Room::Entry }
  end
  

end
