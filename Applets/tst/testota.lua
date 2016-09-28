#!/usr/bin/env lua
---------------------------------------------------------------------------------------------------
-- Purpose: Main Applet for OTA
--
-- Author:  Alan Barker
--
-- Details: Smallish main loop which:
--            * Checks the fme for incoming messages
-- 
-- Copyright Statement:
-- Copyright © 2013 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT") 
local defs
if not onWindows then -- select real modules
    defs  = require "src.defines"
    local fme = require(defs.module.fme)
else
    defs  = require "defines"
end

local utils   = require(defs.module.utils)   
local json    = require(defs.module.json)

local testEvAdd1 = [[ 
{
  "command":"OTA_EVENT_ADD","event_id":1,"bundle_id":2,
  "start_time":12340000,"guard_time":12345000,"activate_time":12349999,
  "policy":"OTA_POLICY_FORCE","device_list":["01:02:03:04:05:06:07:00","01:02:03:04:05:06:07:01"]
}
]]

local testEvAdd2 = [[ 
{
  "command":"OTA_EVENT_ADD","event_id":3,"bundle_id":2,
  "start_time":12340000,"guard_time":12345000,"activate_time":12349999,
  "policy":"OTA_POLICY_FORCE","device_list":["01:02:03:04:05:06:07:03","01:02:03:04:05:06:07:04","01:02:03:04:05:06:07:05"]
}
]]
local testEvStrt    = [[ {"command":"OTA_EVENT_START","event_id":1} ]]
local testEvCancel  = [[ {"command":"OTA_EVENT_CANCEL","event_id":1} ]]
local testEvDel     = [[ {"command":"OTA_EVENT_DELETE","event_id":1} ]]
local testEvStat    = [[ {"command":"OTA_EVENT_STATUS","event_id":1} ]]
local testEvList    = [[ {"command":"OTA_EVENT_LIST","event_id":1} ]]
local testCmds = {}
local testIdx = 0

---------------------------------------------------------------------------------------------------
local function addTestSWmsg(payload)
    testIdx = testIdx + 1
    local m = {}
    m["TYPE"]     = "MS"
    m["Payload"]  = payload

    testCmds[testIdx] = m
end

---------------------------------------------------------------------------------------------------
local function addTestNCPmsg(eid)
    testIdx = testIdx + 1
    local m = {}
    m["TYPE"]         = "OTA"
    m["command"]      = "eid_to_ncp"
    m["result_code"]  = 0
    m["eid"]          = eid
    m["ncp"]          = 1

    testCmds[testIdx] = m
end

---------------------------------------------------------------------------------------------------
local function addTestOTAmsg(...)
    testIdx = testIdx + 1
    -- construct the payload
    local arg = {...}  -- TODO:
    if arg == nil then
        -- Lua 5.1 the vararg variable arg has been abandoned in favour of this
        arg = {...}
    end

    local payload = ""
    local i, v
    for i, v in pairs(arg) do
        if payload ~= "" then
            payload = payload .. ","
        end
        payload = payload .. tostring(v)
    end
   
    local m = {}
    m["TYPE"]         = "OTA"
    m["command"]      = "cmd_to_ncp"
    m["result_code"]  = 0
    m["payload"]      = payload

    testCmds[testIdx] = m
end

---------------------------------------------------------------------------------------------------
local function initTestMsgList()
    local eid1 = "01:02:03:04:05:06:07:00"
    local eid2 = "01:02:03:04:05:06:07:01"
    local eventId = 1
    local bundleId = 2
    addTestSWmsg(testEvAdd1)
    addTestSWmsg(testEvAdd2)
    addTestSWmsg(testEvStrt)
    addTestNCPmsg(eid1)
    addTestOTAmsg("PolicySet",      eventId, eid1, "POLICY", "OTA_STATUS_SUCCESS")
    addTestOTAmsg("ImageAdd",       eventId ,eid1, bundleId, "OTA_STATUS_SUCCESS")
    addTestOTAmsg("UpgradeDevice",  eventId, eid1, bundleId, "OTA_STATUS_SUCCESS")
    addTestNCPmsg(eid2)
    addTestOTAmsg("UpgradeDevice",  eventId, eid2, bundleId, "OTA_STATUS_SUCCESS")
    --addTestOTAmsg("PolicyReset",    eventId, eid, "OTA_STATUS_SUCCESS")
    --addTestOTAmsg("ImageDelete",    eventId, eid, bundleId, "OTA_STATUS_SUCCESS")
    --addTestSWmsg(testEvStat)
    --addTestSWmsg(testEvList)
    --addTestSWmsg(testEvCancel)
    --addTestSWmsg(testEvDel)
    testIdx = 0
end

initTestMsgList()
testTicks = 0
---------------------------------------------------------------------------------------------------
function testMsg()
    testTicks = testTicks + 1
    if testTicks > 10 then
        testIdx = testIdx + 1
        testTicks = 0
        return testCmds[testIdx]
    else
        return nil
    end
end




