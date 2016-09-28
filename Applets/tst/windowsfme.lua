#!/usr/bin/env lua
---------------------------------------------------------------------------------------------------
-- Purpose: Stubbed version of 'fme' to be used in testing on a Windows OS
--
-- Author:  Jeremy Kincaid
--
-- Details: 
-- 
-- Copyright Statement:
-- Copyright © 2014 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice. 
---------------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT") 
local defs = require "src.defines"
local socket = require("socket")


---------------------------------------------------------------------------------------------------
-- Taken from Programming in Lua, 2nd Ed, p142
-- means that this is used as a module:
-- local utils = require "utils"
-- utils.dbPrint(...)
local modname = ...
local M = {}
_G[modname] = M
package.loaded[modname] = M

-- listens for the CLI command to add a meter. Since running on windows this is an easy
-- way to fake a CONTROL_ADD message to the device app. Intercept the EID from here.
M.serverSocket = assert(socket.bind("127.0.0.1", 2066))
M.serverSocket:settimeout(nil,'b')
M.clientSocket = nil
function M.addDeviceUsingCLI()
  -- listen for connection if we don't have one already
  local clientConn = M.serverSocket:accept()
  if (clientConn ~= nil) and (nil ~= M.clientSocket) then
    M.clientSocket:close()
    M.clientSocket = nil
  elseif nil == M.clientSocket then
    M.serverSocket:settimeout(nil,'b')
  end
  
  if clientConn ~= nil then
    M.clientSocket = clientConn
    M.serverSocket:settimeout(2,'b')
  end
  
  -- check existing connection for messages
  if nil ~= M.clientSocket then
    local rxMsg, sockErr, remainder = M.clientSocket:receive(255)
    if (nil ~= remainder) and (0 < string.len(remainder)) then
      rxMsg = remainder
    end
    -- extract the EID
    if nil ~= rxMsg then
      local eid = string.sub(rxMsg, 14, string.len(rxMsg) - 12)
      -- de-colonise the eid
      eid = string.sub(eid,1,2) .. string.sub(eid,4,5) .. string.sub(eid,7,8) .. string.sub(eid,10,11) .. 
            string.sub(eid,13,14) .. string.sub(eid,16,17) .. string.sub(eid,19,20) .. string.sub(eid,22,23)
      -- register the EID for later use
      M.registerMeter(eid)
    end
  end
end

-- a bitwise XOR function as this version of Lua doesn't ship with one.
local XOR_l =
{ 
   {0,1},
   {1,0},
}

local function xor(a,b)
   pow = 1
   c = 0
   while a > 0 or b > 0 do
      c = c + (XOR_l[(a % 2)+1][(b % 2)+1] * pow)
      a = math.floor(a/2)
      b = math.floor(b/2)
      pow = pow * 2
   end
   return c
end

-- Performs a simple XOR checksum on a string and returns the character result if
-- successful, otherwise returns nil. 
-- payload = the string to perform the checksum on
local function checksum(payload)
  if nil ~= payload then
    -- used to store the checksum value
    local chksum = 0
    -- used to store the index into the string have the XOR checksum performed on it
    local index = 1
    
    -- loop over each byte in string performing an XOR checksum
    while(index <= string.len(payload)) do
      chksum = xor(chksum, string.byte(payload,index))
      index = index + 1
    end
    
    -- clear the most significant bit if set
    if chksum >= 128 then
      chksum = chksum - 128
    end
    
    -- convert back to a character
    return string.char(chksum)
  else
    return nil
  end
end

---------------------------------------------------------------------------------------------------
-- Test function to return a series of strings as fake Freestyle Switch request messages
local DO_NOTHING          = 0
local DO_DISCOVERY        = 1
local DO_GET_AUDIT_TRAIL  = 2
local DO_GET_EXT_HISTORY  = 3
local DO_COMMAND_START    = 4
local DO_RAW_RTU          = 5
local action = DO_RAW_RTU

local eidList = {}
function M.registerMeter(eid)
  if nil ~= eid then -- make sure we aren't registering nil
    if nil == eidList[eid] then -- make sure it isn't already registered
      eidList[eid] = {}
      eidList[eid]["eid"] = eid
      eidList[eid]["registered"] = false
      eidList[eid]["action"] = DO_GET_EXT_HISTORY
    end
  end
end

local m_index = nil
local m_device = nil
function M.getmessage(context)
    local eid = nil
    local msg = {}
    
    -- check for new connections and registrations of devices
    M.addDeviceUsingCLI()
    -- if new devices then register them
    local index, device = nil
    local hasMore = true
    while true == hasMore do
      index, device = next(eidList, index)
      
      if nil ~= device then
        if false == device["registered"] then
          -- create a COMMAND_START message for the device app
          action = DO_COMMAND_START
          eid = device["eid"]
          hasMore = false
        end
      else
        hasMore = false
        eid = nil
      end
    end
    
    -- if no device need registering then send a test message
    if nil ~= eid then
      msg["eid"] = eid
    else
      -- using an existing device, send a test message
      m_index, m_device = next(eidList, m_index)
      if nil ~= m_device then
        eid = m_device["eid"]
        action = m_device["action"]
      end
    end

    -- only do packet stuff if we have an eid to use
    if nil ~= eid then
      if DO_NOTHING == action then
        msg = nil
      elseif DO_GET_AUDIT_TRAIL == action then
        msg["TYPE"] = "MS"
        msg["payload"] = string.sub(eid,1,4) .. "0010000000"
        msg["msgname"] = "rtu_raw"
        msg["msgid"] = ""
      elseif DO_GET_EXT_HISTORY == action then
        msg["TYPE"] = "MS"
        msg["payload"] = string.sub(eid,1,4) .. "0200000000"
        msg["msgname"] = "rtu_raw"
        msg["msgid"] = ""
      elseif DO_COMMAND_START == action then
        msg["TYPE"] = "CONTROL_START"
        msg["msgid"] = ""
        msg["eid"] = "2a:c6:00:90:e8:39:a8:32"
        -- assume success because at this stage no nice way to send a success message back here
        device["registered"] = true 
      elseif DO_RAW_RTU == action then
        msg["TYPE"] = "MS"
        msg["payload"] = "0500010000"
        msg["msgname"] = "SEND_RAW"
        msg["msgid"] = 17
      end
    end
    
    return msg
end

function M.sendmessage(context, msg, text)
end

function M.time()
  return os.date
end

function M.sleep(delayTime)
end

