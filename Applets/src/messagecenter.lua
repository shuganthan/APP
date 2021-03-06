local onWindows = (os.getenv("OS") == "Windows_NT")
local def
if not onWindows then -- select real modules
  def  = require "src.defines"
else
  def  = require "defines"
end
local fme     = require (def.module.fme)
local json    = require (def.module.json)
local ieee754 = require (def.module.ieee754)

mcenter = {}
mcenter.rtuDevice = {}
mcenter.rtuDevice.list = {}

mcenter.tancyConfig = {}

Tianhui = {}
Tianhui.ptype = {}
Tianhui.ptype["ptype34"] = 34
Three3gnic_file = {}
Three3gnic_file[1] = def.THREEGNIC_TEMP
Three3gnic_file[2] = def.THREEGNIC_PRSR
Three3gnic_file[3] = def.THREEGNIC_SMPI
Three3gnic_file[4] = def.THREEGNIC_UPLI

function hexasciitostring ( hexascii )

    hastr = ""
    local len = string.len ( hexascii )
    local i = 1
    local j = i + 1
    while (j <= len) do
        hastr = hastr .. string.char ( tonumber( string.sub( hexascii, i , j ), 16 ) )
        i = i + 2
        j = i + 1
    end
    return  hastr
end


mcenter.rtuDevice.new = function(rtuEid)
  mcenter.rtuDevice.list[rtuEid] = {}
  mcenter.rtuDevice.list[rtuEid].eid = rtuEid
  mcenter.rtuDevice.list[rtuEid].msgRxTimeout = os.time() + def.DATA_RX_TIMEOUT
  mcenter.rtuDevice.list[rtuEid].invalidPduCount = 0 
  -- SETTING THE DEFAULT VALUES
  mcenter.tancyConfig[rtuEid] = {}
  mcenter.tancyConfig[rtuEid]["sap"] = "00"..string.format("%04x", 0)
  mcenter.tancyConfig[rtuEid]["snp"] = "01"..string.format("%04x", 0)
  mcenter.tancyConfig[rtuEid]["alp"] = "02"..string.format("%04x", 0)
  mcenter.tancyConfig[rtuEid]["hta"] = "03"..ieee754.get32BitIEEE754Hexstr(0)
  mcenter.tancyConfig[rtuEid]["lta"] = "04"..ieee754.get32BitIEEE754Hexstr(0)
  mcenter.tancyConfig[rtuEid]["hpa"] = "05"..ieee754.get32BitIEEE754Hexstr(0)
  mcenter.tancyConfig[rtuEid]["lpa"] = "06"..ieee754.get32BitIEEE754Hexstr(0)

end

mcenter.sendData2Switch = function(msg,fmeContext)
  local rxTbl             = {}
  local str               = msg["timestamp"]
  rxTbl["cid"]            = 0
  rxTbl["flags"]          = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
  rxTbl["TYPE"]           = "MS"
  rxTbl["msgid"]          = def.SEND_DATA
  rxTbl["msgname"]        = def.name[def.SEND_DATA]
  rxTbl["eid"]            = msg["eid"]
  rxTbl["payload"]        = msg["payload"]  
  rxTbl["devid"]          = msg["id"]
  rxTbl["ptype"]          = msg["ptype"]
  if rxTbl["ptype"]  == Tianhui.ptype["ptype34"] then
      rxTbl["temperature"]    = string.format( "%.2f",msg["temperature"])
      rxTbl["humidity"]       = string.format( "%.2f",msg["humidity"])
      rxTbl["inletpressure"]  = string.format( "%.2f",msg["inletpressure"])
      rxTbl["outletpressure"] = string.format( "%.2f",msg["outletpressure"])
  end
  rxTbl["timestamp"]      = string.sub(str,1,2).."-"..string.sub(str,3,4).."-"..string.sub(str,5,6).." "..string.sub(str,7,8)..":"..string.sub(str,9,10)..":"..string.sub(str,11,12)
  rxTbl[def.RESULT_CODE]  = def.RESPONSE_OK
  print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"APP SENDING CMD:",rxTbl["msgname"],"TO EID:",rxTbl["eid"],"To SWITCH\n");
  fme.sendmessage(fmeContext,rxTbl)
end


mcenter.sendAlert2Switch = function(eid,errorId,fmeContext)
  local rxTbl             = {}
  rxTbl["cid"]            = 0
  rxTbl["flags"]          = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
  rxTbl["TYPE"]           = "MS"
  rxTbl["msgid"]          = def.SEND_APP_ALERT
  rxTbl["msgname"]        = def.name[def.SEND_APP_ALERT]
  rxTbl["eid"]            = eid 
  rxTbl["alert_code"]     = errorId
  rxTbl["alert_desc"]     = def.alert[errorId]
  rxTbl[def.RESULT_CODE]  = def.RESPONSE_OK
  print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"APP SENDING CMD:",rxTbl["msgname"],"TO EID:",rxTbl["eid"],"To SWITCH\n")
  fme.sendmessage(fmeContext,rxTbl)
end

mcenter.process3gnicRequest = function ( msg ) 
    local param = {}
    local file = ""
    local f_handle
    if ( msg["msgname"] == def.name[def.SET_CONFIG_TEMPERATURE]) then
       param[1] = "&TLL=" .. ieee754.get32BitIEEE754Hexstr( tonumber ( msg["ll"] ) )
       param[2] = "&TUL=" .. ieee754.get32BitIEEE754Hexstr( tonumber ( msg["ul"] ) )
       file = file .. def.THREEGNIC_TEMP .. string.gsub(msg["eid"],"%W",'')
    elseif (  msg["msgname"] == def.name[def.SET_CONFIG_PRESSURE] ) then
        param[1] = "&PLL=" .. ieee754.get32BitIEEE754Hexstr( tonumber ( msg["ll"] ) )
        param[2] = "&PUL=" .. ieee754.get32BitIEEE754Hexstr( tonumber ( msg["ul"] ) )
        file = file .. def.THREEGNIC_PRSR .. string.gsub(msg["eid"],"%W",'')
    elseif ( msg["msgname"] == def.name[def.SET_CONFIG_SAMPLING_INTERVAL] ) then
        param[1] = "&SPI=" .. string.format( "%02x", msg["si"] )
        file = file .. def.THREEGNIC_SMPI .. string.gsub(msg["eid"],"%W",'')
    elseif ( msg["msgname"] == def.name[def.SET_CONFIG_UPLOAD_INTERVAL] ) then
        param[1] = "&ULI=" .. string.format ( "%02x", msg["si"] )
        file = file .. def.THREEGNIC_UPLI .. string.gsub(msg["eid"],"%W",'')
    end
    f_handle = io.open ( file, "w" )
    for i = 1, #param do 
        f_handle:write ( param[i] ) 
    end
    io.close ( f_handle ) 
end

mcenter.processTancyRequest = function( msg )

  mcenter.tancyConfig[msg["eid"]]["sap"] = "00"..string.format("%04x",msg["save_period"] )
  mcenter.tancyConfig[msg["eid"]]["snp"] = "01"..string.format("%04x",msg["send_period"] )
  mcenter.tancyConfig[msg["eid"]]["alp"] = "02"..string.format("%04x",msg["alarm_period"])
  mcenter.tancyConfig[msg["eid"]]["hta"] = "03"..ieee754.get32BitIEEE754Hexstr(msg["temperature_high"] )
  mcenter.tancyConfig[msg["eid"]]["lta"] = "04"..ieee754.get32BitIEEE754Hexstr(msg["temperature_low"]  )
  mcenter.tancyConfig[msg["eid"]]["hpa"] = "05"..ieee754.get32BitIEEE754Hexstr(msg["pressure_high"] )
  mcenter.tancyConfig[msg["eid"]]["lpa"] = "06"..ieee754.get32BitIEEE754Hexstr(msg["pressure_low"] )

end

mcenter.processTancyConfig = function (msg,fmeContext)
 
  local smsg = {}
  smsg["TYPE"] = "A2"
  smsg["msgname"] = "CONFIG"
  smsg["eid"]  = msg["eid"]
  smsg["payload"] =   mcenter.tancyConfig[msg["eid"]]["sap"] .. mcenter.tancyConfig[msg["eid"]]["snp"] .. 
                      mcenter.tancyConfig[msg["eid"]]["alp"] .. mcenter.tancyConfig[msg["eid"]]["hta"] .. 
                      mcenter.tancyConfig[msg["eid"]]["lta"] .. mcenter.tancyConfig[msg["eid"]]["hpa"] ..                                
                      mcenter.tancyConfig[msg["eid"]]["lpa"]  
 --[[
 -- Adding mod256 checksum
 local plen = string.len(smsg["payload"])
 local i = 1
 local sum = 0
 local mod = 0
 while i <= plen do
   sum = sum + tonumber ( string.sub(smsg["payload"],i,i+1),16 )
   i = i + 2
 end
 mod = math.fmod(sum,256)
 smsg["payload"] = smsg["payload"] .. string.format("%02x",mod)
 ]]--
 fme.sendmessage ( fmeContext, smsg )

end

mcenter.process3GNICConfig = function (msg,fmeContext)
    
    local f_handle
    local smsg = {}
    local buf
    local file = ""
    smsg["TYPE"]     = "3G"
    smsg["msgname"]  = "CONFIG"
    smsg["payload"]  = ""
    smsg["eid"]      = msg["eid"]
    for i=1,#Three3gnic_file do
        file = file ..Three3gnic_file[i]..string.gsub(msg["eid"],"%W",'')
        f_handle = io.open ( file , "r" )
        if ( f_handle ~= nil ) then
            buf = f_handle:read("*lines")
            if ( buf ~= nil ) then
                smsg["payload"] = smsg["payload"] .. buf
            end
            io.close ( f_handle )
        end
        file = ""
    end
    smsg["payload"] = smsg["payload"] .. "&DAT=" .. string.format ( "%x", (os.time() - 946684800) )  -- UTC TIME EPOCH SINCE 2000

    fme.sendmessage ( fmeContext, smsg ) 
end

mcenter.processIncoming = function(msg,fmeContext)
  print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION," RECEIVED A MSG REQUEST FROM SWITCH\n")
  if msg["msgname"] == def.name[def.SET_CONFIG_TEMPERATURE]  or msg["msgname"] == def.name[def.SET_CONFIG_PRESSURE] or msg["msgname"] == def.name[def.SET_CONFIG_SAMPLING_INTERVAL] 
     or msg["msgname"] == def.name[def.SET_CONFIG_UPLOAD_INTERVAL] then 
    mcenter.process3gnicRequest( msg )
  elseif msg["msgname"] == def.name[def.SET_TANCY_CONFIG] then
    mcenter.processTancyRequest( msg )
  end
end

mcenter.processTianhui = function(msg,fmeContext)
    if msg["eid"] ~= nil and mcenter.rtuDevice.list[msg["eid"]] ~= nil then
      if msg["payload"] ~= nil then
        print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN UNSOLICITED MSG FROM EID:",msg["eid"],"\n")
        mcenter.rtuDevice.list[msg["eid"]].invalidPduCount = 0
        mcenter.rtuDevice.list[msg["eid"]].msgRxTimeout = os.time() + def.DATA_RX_TIMEOUT
        mcenter.sendData2Switch(msg,fmeContext)
      else
          mcenter.rtuDevice.list[msg["eid"]].invalidPduCount = mcenter.rtuDevice.list[msg["eid"]].invalidPduCount + 1 
          print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN INVALID PDU & INVALID PDU COUNT=",mcenter.rtuDevice.list[msg["eid"]].invalidPduCount,"\n")
          if mcenter.rtuDevice.list["invalidPduCount"] == def.INFORM_INVALID_PDU then  
            mcenter.sendAlert2Switch(msg["eid"],def.INVALID_PDU_ERROR,fmeContext)
          end
     end
   else
       print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN UNSOLICITED DATA FROM UNKNOWN\n")
   end
end

mcenter.sendLora2Switch = function(msg,loraTbl,fmeContext)
    loraTbl["cid"]            = 0
    loraTbl["flags"]          = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
    loraTbl["TYPE"]           = "MS"
    loraTbl["msgid"]          = def.LORA_PAYLOAD
    loraTbl["msgname"]        = def.name[def.LORA_PAYLOAD]
    loraTbl["eid"]            = msg["eid"]
    print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"APP SENDING CMD:",loraTbl["msgname"],"TO EID:",loraTbl["eid"],"To SWITCH\n")
    fme.sendmessage(fmeContext,loraTbl)
end

mcenter.processLora = function (msg, fmeContext )
    local loraPayloadTbl = {}
    local loraTbl          = {}
    if msg["eid"] ~= nil and mcenter.rtuDevice.list[msg["eid"]] ~= nil then
        if msg["payload"] ~= nil then
            print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN UNSOLICITED MSG FROM EID:",msg["eid"],"\n")
            loraPayloadTbl = json.decode ( msg["payload"] )
            loraTbl["EUI"]     = loraPayloadTbl["DevEUI_uplink"]["DevEUI"]
            loraTbl["Time"]    = loraPayloadTbl["DevEUI_uplink"]["Time"]
            loraTbl["RSSI"]    = loraPayloadTbl["DevEUI_uplink"]["LrrRSSI"]
            loraTbl["SNR"]     = loraPayloadTbl["DevEUI_uplink"]["LrrSNR"]
            loraTbl["payload"] = hexasciitostring ( loraPayloadTbl["DevEUI_uplink"]["payload_hex"] ) 
            mcenter.sendLora2Switch(msg,loraTbl,fmeContext )
        end
    else
         print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN UNSOLICITED DATA FROM UNKNOWN\n")
    end
end

mcenter.process3GNIC = function ( msg, fmeContext )
    
    local tbl = {}
    local rsptbl = {}
    local resp = {}
    local rsp  = {}
    resp = { pressure = nil , temperature = nil }
    rsp  = { pressure = nil , temperature = nil }
    local flag = 0
    local j = 1
    local i = 0
    local k = 0
    local alarmflag = 0
    local payloadlength = 0 
    mcenter.process3GNICConfig(msg,fmeContext)

    payloadlength = string.len(msg["payload"] )
    if msg["eid"] ~= nil and mcenter.rtuDevice.list[msg["eid"]] ~= nil then
        if msg["payload"] ~= nil then
            a,b = string.find ( msg["payload"] , "ALM" ) 
            if ( a ~= nil and b ~= nil ) then
                alarmflag = 1
            end
            print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN UNSOLICITED MSG FROM EID:",msg["eid"],"\n")
            for word in string.gmatch( msg["payload"] , '.') do
                k = k + 1
                if ( flag == 0 ) then
                    i = i + 1
                    tbl[i] = ""
                    tbl[i] = tbl[i] .. word
                    flag = 1
                elseif flag ==  1 then
                    if word == '&' then
                        flag = 2
                    end
                    tbl[i] = tbl[i] .. word
                elseif flag == 2 then
                    if word == '&' then
                        flag = 0
                        if ( i == 1 ) then
                            rsptbl["sid"]  = string.sub ( tbl[i] ,27,38 )
                        end 
                        if ( i > 1 ) then
                            resp[j] = { pressure = nil , temperature = nil }
                            resp[j]["pressure"]       = string.sub ( tbl[i] , 5,12 )
                            resp[j]["temperature"]    = string.sub ( tbl[i] , 18,25)
                            j = j + 1
                        end
                    else
                        tbl[i] = tbl[i] .. word
                        if ( k == payloadlength ) then
                            resp[j] = { pressure = nil , temperature = nil }
                            resp[j]["pressure"]       = string.sub ( tbl[i] , 5,12 )
                            resp[j]["temperature"]    = string.sub ( tbl[i] , 18,25)
                        end
                    end
                end
            end
        end
    else
         print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED AN UNSOLICITED DATA FROM UNKNOWN\n")
         return 0
    end

    -- Retrieving the alarm 
    if alarmflag == 1 then
       rsptbl["alarm"] = tonumber (string.sub ( tbl[3],5,12),16 )
    end 

    -- Converting the hex ascii to iee754 string.
    for k, v in pairs ( resp ) do
        for i,j in pairs ( v ) do
            fpno    = ieee754.get32BitIEEE754(j)
            if rsp[k] == nil then
               rsp[k] = { pressure = nil , temperature = nil }
            end
            if i == "temperature" then
                rsp[k]["temperature"] = ieee754.makeSingleprecisionFP(fpno )
            elseif i == "pressure" then
                rsp[k]["pressure"] = ieee754.makeSingleprecisionFP(fpno )
            end
        end
    end
    -- SENDING MESSAGE TO SWITCH 
    rsptbl["cid"]            = 0
    rsptbl["flags"]          = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
    rsptbl["TYPE"]           = "MS"
    if alarmflag == 0 then
        rsptbl["msgid"]          = def.GNIC_PAYLOAD
        rsptbl["msgname"]        = def.name[def.GNIC_PAYLOAD]
    else
        rsptbl["msgid"]          = def.GNIC_ALERT
        rsptbl["msgname"]        = def.name[def.GNIC_ALERT]
    end
    rsptbl["eid"]            = msg["eid"]
    rsptbl["payload"]        = json.encode ( rsp )  
    print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"APP SENDING CMD:",rsptbl["msgname"],"TO EID:",rsptbl["eid"],"To SWITCH\n")
    fme.sendmessage(fmeContext,rsptbl)
end

mcenter.processTancy = function ( msg, fmeContext )

  local tbl = {}
  local fpno = 0
  local sp_fpstr = ''
  local vol_high = 0
  local vol_low  = 0 
  local total_vol = 0
  local rsptbl = { }
  local i =1
  local idx = 1
  local almtbl = {}
  local tstamp = ''
  
  mcenter.processTancyConfig(msg,fmeContext)
  if msg["eid"] ~= nil and mcenter.rtuDevice.list[msg["eid"]] ~= nil then
    local payloadlength = string.len(msg["payload"])
    if msg["length"] == payloadlength then 
      if (msg["payload_type"] > 0) and (msg["payload_type"] <=6) then
        -- Send an alarm
        almtbl["cid"]            = 0
        almtbl["flags"]          = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
        almtbl["TYPE"]           = "MS"
        almtbl["msgid"]          = def.TANCY_ALERT
        almtbl["msgname"]        = def.name[def.TANCY_ALERT]
        almtbl["eid"]            = msg["eid"]
        if msg["payload_type"] == 0x01 then
          almtbl["alarm"]        = "High Temperature Alarm" 
        elseif msg["payload_type"] == 0x02 then
          almtbl["alarm"]        = "Low Temperature Alarm"
        elseif msg["payload_type"] == 0x03 then
          almtbl["alarm"]        = "High Pressure Alarm"
        elseif msg["payload_type"] == 0x04 then
          almtbl["alarm"]        = "Low Pressure Alarm"
        end
        fme.sendmessage(fmeContext,almtbl)
      end
      for i=1,msg["count"] do
        tstamp = string.sub(msg["payload"], idx , idx+7 )
        tbl["timestamp"] = tonumber ( (string.sub(tstamp,7,8)..string.sub(tstamp,5,6)..string.sub(tstamp,3,4)..string.sub(tstamp,1,2)),16 )
        idx = idx + 8
        -- skip modbus header
        idx = idx + 2 + 2 + 2
        tbl["vol_high"]   = string.sub(msg["payload"],idx,idx+7 )
        idx = idx + 8
        tbl["vol_low"] = string.sub (msg["payload"],idx ,idx+7 )
        idx = idx + 8
        tbl["standard_flow"] = string.sub (msg["payload"],idx ,idx+7 )
        idx = idx + 8
        tbl["flow"] = string.sub ( msg["payload"],idx ,idx+7 )
        idx = idx + 8
        tbl["temperature"] = string.sub ( msg["payload"],idx ,idx+7 )
        idx = idx + 8
        tbl["pressure"]  = string.sub ( msg["payload"],idx ,idx+7)
        idx = idx + 8
        -- skip crc 
        idx = idx + 4
        -- pack the data and push it to switch
        for name, value in pairs(tbl) do
          if name ~= "timestamp" then
            fpno     = ieee754.get32BitIEEE754(value) -- Send hexstr and Receive floating point number
            if name == "vol_high" then
              vol_high = fpno
            elseif name == "vol_low" then
              vol_low = fpno
            else
              sp_fpstr = ieee754.makeSingleprecisionFP(fpno) -- receive single precision fp string    
              rsptbl[name] = sp_fpstr
            end
          else
            rsptbl["timestamp"] = value
          end  
        end
        -- As mentioned in Tancy Flowmeter Comms Protocol reference doc ( SEE NOTE 3 )
        total_vol = ( 1000000 * vol_high ) + vol_low
        rsptbl["total_volume"]  = ieee754.makeSingleprecisionFP(total_vol)
        -- Send the Tancy data to switch
        rsptbl["cid"]            = 0
        rsptbl["flags"]          = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
        rsptbl["TYPE"]           = "MS"
        rsptbl["msgid"]          = def.READ_FLOW_DATA
        rsptbl["msgname"]        = def.name[def.READ_FLOW_DATA]
        rsptbl["eid"]            = msg["eid"]
        fme.sendmessage(fmeContext,rsptbl)
      end
    else
        print("LUA App received Tancy payload with incorrect length\n")
    end
  end
end

return mcenter
