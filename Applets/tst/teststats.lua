--------------------------------------------------------------------------------------------------
-- Purpose: Unit test code for the stats module
--
-- Author:  Alan Barker
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
local defs
local stats
if not onWindows then -- select real modules
    defs  = require "src.defines"
else
    defs  = require "defines"
end

local utils   = require(defs.module.utils) 
require "sinewave" 
require "qosmsgs"
require "socket"
require(defs.module.stats)

---------------------------------------------------------------------------------------------------
local function sleep(sec)
    socket.select(nil, nil, sec)
end

---------------------------------------------------------------------------------------------------
local function simulate(context)
    local s = Stats.new(context)
    
    local m = LocalMsg.new()
    local msg = m.make("D000000000000001", -12,   11)
    s.handleNCPmessage(msg)
    socket.sleep(2)
    --                  EID                RSSI, LQI            
    msg       = m.make("D000000000000001", -2,   2)
    s.handleNCPmessage(msg)
    socket.sleep(2)
  
    msg       = m.make("D000000000000002", -99,  55)
    s.handleNCPmessage(msg)
    socket.sleep(2)    
  
    msg       = m.make("D000000000000001", -3,   30)
    s.handleNCPmessage(msg)
    socket.sleep(2)  
  
    s.report()
    utils.dbSafePrint(1, "  DONE  ")
end

---------------------------------------------------------------------------------------------------
if onWindows then
    sineTest()
    utils.setTime(0)
    QosMsgTest.routerMsgTest()
    --QosMsgTest.localMsgTest()
    utils.dbSafePrint(1, "  DONE  ")
end




