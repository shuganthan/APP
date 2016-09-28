---------------------------------------------------------------------------------------------------
-- Purpose: Main 
--
-- Copyright Statement:
-- Copyright © 2014 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored,
-- transcribed in an information retrieval system, translated into -- any language, or transmitted
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise,
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
-------------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT")
local def
if not onWindows then
  def = require "src.defines"
else
  def = require "defines"
end
local fme     = require(def.module.fme)
local mcenter = require(def.module.messagecenter)
--------------------------------------------------------------------------------------------------
-- MODBUS DEVICE LIST
--------------------------------------------------------------------------------------------------
modbusDev = {}
local modbusDevCount = 0
if def.simOn == 1 then
  local timeout_val = 0
end

--------------------------------------------------------------------------------------------------
new = function(eid)
  local dev              = {} 
  dev.eid                = string.lower(eid) 
  return dev
end

--------------------------------------------------------------------------------------------------
clearall = function()
  for eid, modbus in pairs(modbusDev) do
    modbusDev[eid] = nil
  end
end

--------------------------------------------------------------------------------------------------
sendFMECtrlStart = function(rtuEid,fmeContext)
    local sendMsgTbl = {}
    sendMsgTbl["TYPE"]           = "TH"
    sendMsgTbl["msgid"]          = 1
    sendMsgTbl["msgname"]        = "CONTROL_RTU"
    sendMsgTbl["eid"]            = rtuEid
    sendMsgTbl["control_flag"]   = 1
    fme.sendmessage(fmeContext,sendMsgTbl)
end

---------------------------------------------------------------------------------------------------
sendFMECtrlStop = function(rtuEid,fmeContext)
   local sendMsgTbl = {}
   sendMsgTbl["TYPE"]           = "TH"
   sendMsgTbl["msgid"]          = 1
   sendMsgTbl["msgname"]        = "CONTROL_RTU"
   sendMsgTbl["eid"]            = rtuEid
   sendMsgTbl["control_flag"]   = 0
   fme.sendmessage(fmeContext,sendMsgTbl)
end

--------------------------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------------------------
local function main()

	local msg = nil
    local fmeContext = {}
    fmeContext = fme.open()
    if def.simOn == 1 then
        timeout_val = os.time() + 300
    end
	while true do
		msg = fme.getmessage(fmeContext)

		if msg ~= nil then	-- message available
		  if msg["TYPE"]     == "MS" then
            mcenter.processIncoming(msg,fmeContext)
          elseif msg["TYPE"] == "TH" then
            mcenter.processTianhui(msg,fmeContext)
          elseif msg["TYPE"] == "LR" then
            mcenter.processLora(msg,fmeContext)
          elseif msg["TYPE"] == "3G" then
            if ( msg["msgname"] == "CONFIG" ) then
                mcenter.process3GNICConfig(msg,fmeContext)
            end
            mcenter.process3GNIC(msg,fmeContext)
	      elseif msg["TYPE"] == "A2" then
            if ( msg["msgname"] == "CONFIG" ) then
                mcenter.processTancyConfig(msg,fmeContext)
            end
            mcenter.processTancy(msg,fmeContext)
          elseif msg["TYPE"] == "CONTROL_START" then
            if modbusDev[msg["eid"]] == nil then
                modbusDev[msg["eid"]] = new(msg["eid"]) 
                modbusDevCount = modbusDevCount + 1
                mcenter.rtuDevice.new(msg["eid"])
                --sendFMECtrlStart(msg["eid"],fmeContext)
                print(def.seperatorEqual)
                print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"DEVICE REGISTERED SUCCESSFULLY EID:",msg["eid"],"TOTAL DEVICES REGISTERED NOW=",modbusDevCount,"\n")
                print(def.seperatorEqual)
            else
                print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"DEVICE ALREADY EXIST EID:",msg["eid"],"\n")
            end
  		  elseif msg["TYPE"] == "CONTROL_STOP" then
            modbusDev[msg["eid"]] = nil
            modbusDevCount = modbusDevCount - 1
            --sendFMECtrlStop(msg["eid"],fmeContext)
            print(def.seperatorEqual)
            print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"DEVICE UNREGISTERED SUCCESSFULLY EID:",msg["eid"],"TOTAL DEVICES REGISTERED NOW=",modbusDevCount,"\n")
            print(def.seperatorEqual)
  		  elseif msg["TYPE"] == "CONTROL_STOP_EXIT" then
            clearall()
  		  else
              print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED UNKNOWN MSG\n")
		  end
        end

		if msg == nil then
          --[[
           for eid,rtu in pairs(mcenter.rtuDevice.list) do
             if mcenter.rtuDevice.list[eid].msgRxTimeout <= os.time() then
               mcenter.rtuDevice.list[eid].msgRxTimeout  = os.time() + def.DATA_RX_TIMEOUT
               mcenter.sendAlert2Switch(mcenter.rtuDevice.list[eid].eid,def.DATA_RX_TIMED_OUT_ERROR,fmeContext)
             end
          end
          ]]--
          if def.simOn == 1 then
            if timeout_val <= os.time() then
              for eid,rtu in pairs(mcenter.rtuDevice.list) do 
                local msg = {}
                msg["eid"] = mcenter.rtuDevice.list[eid].eid
                mcenter.sendAlert2Switch(msg["eid"],def.DATA_RX_TIMED_OUT_ERROR,fmeContext)
                fme.sleep(5)
                mcenter.sendAlert2Switch(msg["eid"],def.INVALID_PDU_ERROR,fmeContext)
                fme.sleep(5)
                msg["valid_pdu"] = 1
                msg["payload"] = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 78"
                mcenter.sendData2Switch(msg,fmeContext)
                timeout_val = os.time() + 300
              end
            end
          end
         fme.sleep(1) 
        end
    end
end

---------------------------------------------------------------------------------------------------
local function fatalerr()
  print(debug.traceback())
end
---------------------------------------------------------------------------------------------------
-- call main with xpcall, which catches fatal errors and calls dump to print out stack trace
---------------------------------------------------------------------------------------------------
print(xpcall(main, fatalerr))
