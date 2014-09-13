require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :ComplexStore do
 
  data Token 
  data Resource

  data UserID 
  data SessionID 
  data Password # password

  data Amount
  data TxID # Transaction ID
  data TxInfo[order: OrderID, amt: Amount] # Transaction info  

  data OrderID # order ID

  component MyStore [
     passwords: UserID ** Password,
     sessions: UserID ** SessionID,
     price: OrderID ** Amount,
     orders: (dynamic UserID ** OrderID),
     paid: (dynamic UserID ** OrderID)
  ]{    
    typeOf HttpServer

    op Login[uid: UserID, pwd: Password, ret: SessionID] {
      allows { pwd == passwords[uid] and ret == sessions[uid]}
    }
  
    op PlaceOrder[uid: UserID, oid: OrderID] {
      updates { orders.insert(uid**oid) }
    }

    op Checkout[sid: SessionID] {
      
    }
  
    op NotifyPayment[oid: OrderID, amt: Amount] {
      
    }

  }

  component PaymentService [
    transactions: (dynamic TxID ** TxInfo),
  ]{
    typeOf HttpServer
    
    op MakePayment[oid: OrderID, amt: Amount]{      
      calls { MyStore::NotifyPayment[oid, amt] }
    
      updates { 
        some(t: TxID) | 
          some(i: TxInfo) | 
            transactions.insert(t**i) 
      }
      
    }
  }

  component Customer [
    id: UserID,
    pass: Password
  ]{

    typeOf Browser

    calls { MyStore::Login }
    calls { MyStore::PlaceOrder}
    calls { MyStore::Checkout }
    calls { PaymentService::MakePayment }
    
  }

end
