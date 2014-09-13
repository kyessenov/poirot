require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :ComplexStore do
 
  data UserID 
  secret data SessionID 
  secret data Password # password

  data Amount
  data OrderID # order ID
  data PaymentInfo[order: OrderID, amtCharged: Amount]

  data TxID # Transaction ID
  data TxInfo[order: OrderID, amtPaid: Amount] # Transaction info  

  component MyStore [
     passwords: UserID ** Password,
     sessions: UserID ** SessionID,
     price: OrderID ** Amount,
     orders: (dynamic UserID ** OrderID),
     paid: (dynamic set OrderID)
  ]{    
    typeOf HttpServer

    op Login[uid: UserID, pwd: Password, ret: SessionID] {
      allows { pwd == passwords[uid] and ret == sessions[uid]}
    }
  
    op PlaceOrder[uid: UserID, oid: OrderID] {
      updates { orders.insert(uid**oid) }
    }

    op Checkout[sid: SessionID, ret: PaymentInfo] {
      allows { ret.order == orders[sessions.(sid)] and ret.amtCharged == price[ret.order] }
    }
  
    op NotifyPayment[oid: OrderID] {
      updates { paid.insert(oid) } 
    }
  }

  component PaymentService [
    transactions: (dynamic TxID ** TxInfo),
  ]{
    typeOf HttpServer
    
    op MakePayment[oid: OrderID, amt: Amount]{      
      calls { MyStore::NotifyPayment[oid] }    
      updates { 
        some(t: TxID) | some(i: TxInfo) {
          i.order == oid and
          i.amtPaid == amt and
          transactions.insert(t**i) 
        }
      }      
    }
  }

  component Customer [
    myId: UserID,
    myPwd: Password
  ]{

    typeOf Browser

    calls { MyStore::Login }
    calls { MyStore::PlaceOrder }
    calls { MyStore::Checkout }
#    calls { PaymentService::MakePayment.after MyStore::PlaceOrder}
    calls { PaymentService::MakePayment }
  }

end
