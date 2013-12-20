require 'slang/slang_dsl'

include Slang::Dsl

Arby.conf.sym_exe.convert_missing_fields_to_joins = true


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

    op Checkin[guest: Guest, rm: RoomNumber, ret: Key] do
      guard {
        no self.occupant[rm]
        ret == self.lastKey[rm].nxt
      }
      effects {
        guest.keys = guest.keys + ret
        self.lastKey = self.lastKey + (rm ** ret)
        self.occupant = self.occupant + (rm ** guest.id)
      }
    end

    op Checkout[id: GuestID] do
      guard { some occupant.id }

      effects {
        no occupant.id
      }
    end
  end

  trusted Room [
    num: RoomNumber,
    keys: (set Key),
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

  abstract mod Guest [
    id: GuestID,
    keys: (set Key)
  ] do
    sends { FrontDesk::Checkin }
    sends { FrontDesk::Checkout }
    sends { Room::Entry }
  end

  trusted GoodGuest < Guest
  mod BadGuest < Guest

end
