#!/usr/bin/env lua
---------------------------------------------------------------------------------------------------
-- Purpose: Used for testing the functions related to IEEE-754 conversion
--
-- Author:  Jeremy Kincaid
--
-- Details: Tests a list of Hex values by comparing the result against known answers
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

local utils   = require("src.utils")

local testVector = 
{
  {["hexascii"]="3F800000",["result"]=1.0},
  {["hexascii"]="41000000",["result"]=8.0},
  {["hexascii"]="462B1800",["result"]=10950.0},
  {["hexascii"]="40800000",["result"]=4.0},
  {["hexascii"]="42040000",["result"]=33.0},
  {["hexascii"]="46FD8A00",["result"]=32453.0},
  {["hexascii"]="42740000",["result"]=61.0},
  {["hexascii"]="471DF200",["result"]=40434.0},
  {["hexascii"]="41C3FA360",["result"]=24.4971733093261},
  {["hexascii"]="C243BF60",["result"]=-48.9368896484375},
  {["hexascii"]="C14D20D2",["result"]=-12.8205127716064},
  {["hexascii"]="BFE03EAC",["result"]=-1.75191259384155},
  {["hexascii"]="3C4BB600",["result"]=0.0124335289001464},
  {["hexascii"]="3B8EAB93",["result"]=0.00435394933447241},
  {["hexascii"]="00000000",["result"]=0},
  {["hexascii"]="BF843FE6",["result"]=1.03320002555847},
  {["hexascii"]="4007E69A",["result"] = 2.12345},
  {["hexascii"]="4047E69B",["result"] = 3.12345},
  {["hexascii"]="4094F032",["result"] = 4.654321}
}


local function testUnpack()
  local index, object = nil
  local hasMore = true
  local testResult = false 
  
  while(true == hasMore) do
    index, object = next(testVector, index, object)
    
    if( nil == object ) then
      hasMore = false
    else
      local converted = utils.UnpackIEEE754(object["hexascii"])
      if( converted == object["result"] ) then
        testResult = true
        utils.dbSafePrint(1,"test step succeeded. HEX: ", object["hexascii"], ", expected: ", object["result"], ", actual: ", converted)
      else
        -- figure something out. print error maybe
        utils.dbSafePrint(1,"test step failed. HEX: ", object["hexascii"], ", expected: ", object["result"], ", actual: ", converted)
      end
    end
  end
  
  return testResult
end

function main()
  local testResult = true
  local today = os.time({year=2015, month = 2, day = 24, hour = 15, min = 49, sec = 23})
  utils.dbSafePrint(1, "Test started. ", today, ", ", os.date("%x", today))
  
  if( false == testUnpack() ) then
  end
  
  utils.dbSafePrint(1, "Test completed.")
end

---------------------------------------------------------------------------------------------------
local function fatalerr()
	print("I died ------------------------------------------------")
	print("Program Terminated")
	print(debug.traceback())
end

---------------------------------------------------------------------------------------------------
-- call main with xpcall, which catches fatal errors and calls dump to print out stack trace
---------------------------------------------------------------------------------------------------
print(xpcall(main, fatalerr))
