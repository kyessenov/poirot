# Example e-store model in Poirot
data UserID 
secret data SessionID 
secret data Password # password

data Amount
data OrderID # order ID
data PaymentInfo[order: OrderID, amtCharged: Amount]

data TxID # Transaction ID
data TxInfo[order: OrderID, amtPaid: Amount] # Transaction info  

trusted component MyStore [
  passwords: UserID ** Password,
  sessions: UserID ** SessionID,
  price: OrderID ** Amount,
  orders: (updatable UserID ** OrderID),
  paid: (updatable set OrderID)
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

trusted component PaymentService [
  transactions: (updatable TxID ** TxInfo),
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

trusted component Customer [
  myId: UserID,
  myPwd: Password
]{
  typeOf Browser

  calls { MyStore::Login }
  calls { MyStore::PlaceOrder }
  calls { MyStore::Checkout }
  calls { 
    MyStore::PlaceOrder.then PaymentService::MakePayment do |order, payment|
      order.oid == payment.oid
    end
  }
}
