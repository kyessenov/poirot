require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :SimpleStore do

  data UserID
  data ProductID # product ID
  data ProductInfo # product info
  data Password # password

  component MyStore [
     passwords: UserID ** Password,
     products: ProductID ** ProductInfo,
     orders: (dynamic UserID ** ProductID)
  ]{
    
    typeOf HttpServer

    op Login[uid: UserID, pass: Password] {
      allows { pass == passwords[uid] }
    }

    op GetProduct[pid: ProductID, ret: ProductInfo] {
      allows { ret == products[pid] }
    }
  
    op OrderProduct[uid: UserID, pid: ProductID] {
      # updates { self.orders = orders + uid ** pid }
      updates { orders.insert uid**pid }
    }

  }

  component Customer [
    id: UserID,
    pass: Password
  ]{

    typeOf Browser

    calls { MyStore::Login }
    calls { MyStore::GetProduct }
    calls { MyStore::OrderProduct }
  }

end
