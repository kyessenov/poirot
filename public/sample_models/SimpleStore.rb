data UserID
data OrderID # order ID
secret data SessionID 
secret data Password # password

trusted component MyStore [
  passwords: (updatable UserID ** Password),
  sessions: (updatable UserID ** SessionID),
  orders: (updatable UserID ** OrderID)
]{    
  typeOf HttpServer

  op Login[uid: UserID, pwd: Password, ret: SessionID] {
    ensures { pwd == passwords[uid] and ret == sessions[uid]}
  }

  op Signup[uid: UserID, pwd: Password] {
    updates { passwords.insert(uid**pwd) }
  }
  
  op PlaceOrder[uid: UserID, oid: OrderID] {
    updates { orders.insert(uid**oid) }
  }
  
  op ListOrder[uid: UserID, ret: OrderID] {
    ensures { ret == orders[uid] }
  }
}

trusted component Customer [
  myId: UserID,
  myPwd: Password
]{
  typeOf Browser

  calls { MyStore::Login }
  calls { MyStore::PlaceOrder }
  calls { MyStore::ListOrder }
}

policy myPolicy {
  confidential(MyStore.orders,Customer.myId)
}
