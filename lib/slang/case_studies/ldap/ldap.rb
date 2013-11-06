require 'slang/slang_dsl'

include Slang::Dsl

Slang::Dsl.view :LDAP do
  
  data Record

  trusted LDAPServer [
    records: (set Record)
  ] do
    op GetRecords[ret: (set Record)] do
      effects { ret == records }
    end

    op AddRecord[new: Record] do
      effects { self.records = self.records + new }
    end
  end

  mod LDAPClient [
  ] do
    sends { LDAPServer::GetRecords }
    sends { LDAPServer::AddRecord }
  end
 
end

