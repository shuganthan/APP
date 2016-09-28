#!/usr/bin/env lua
---------------------------------------------------------------------------------------------------
-- Purpose: Used for testing the functions related to IEEE-754 conversion
--
-- Author:  Jeremy Kincaid
--
-- Details: Tests a list of Hex values by comparing the result against known answers
-- 
-- Copyright Statement:
-- Copyright Â© 2013 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT") 

local utils   = require("src.utils")

local testVectorAddition = 
{
  { ["lhs"]={1},	              ["rhs"]=1,    ["start"]=1,  ["result"]={2} },
  { ["lhs"]={1},	              ["rhs"]=10,   ["start"]=1,  ["result"]={11} },
  { ["lhs"]={0x0A},	            ["rhs"]=0xFF, ["start"]=1,  ["result"]={0x01, 0x09} },
  { ["lhs"]={0x3E, 0x08},	      ["rhs"]=0xFF, ["start"]=1,  ["result"]={0x3F,0x07} },
  { ["lhs"]={0xFF, 0xFF, 0x30},	["rhs"]=0xF0, ["start"]=1,  ["result"]={0x01, 0x00, 0x00, 0x20} }
}

local testVectorAdditionN = 
{
  { ["lhs"]={1},	              ["rhs"]={1},                  ["result"]={2} },
  { ["lhs"]={1},	              ["rhs"]={10},                 ["result"]={11} },
  { ["lhs"]={0x0A},	            ["rhs"]={0xFF},               ["result"]={0x01, 0x09} },
  { ["lhs"]={0x3E, 0x08},	      ["rhs"]={0xFF},               ["result"]={0x3F,0x07} },
  { ["lhs"]={0xFF, 0xFF, 0x30},	["rhs"]={0xF0},               ["result"]={0x01, 0x00, 0x00, 0x20} },
  { ["lhs"]={0xF0},	            ["rhs"]={0xFF, 0xFF, 0x30},   ["result"]={0x01, 0x00, 0x00, 0x20} }
} 

local testVectorMul = 
{
  { ["lhs"]={0},          ["rhs"]={0},    ["result"]={0} },
  { ["lhs"]={1},          ["rhs"]={0},    ["result"]={0} },
  { ["lhs"]={1},          ["rhs"]={1},    ["result"]={1} },
  { ["lhs"]={0x01,0x02},  ["rhs"]={0x00}, ["result"]={0x00} },
  { ["lhs"]={0x01,0x02},  ["rhs"]={0x01}, ["result"]={0x01,0x02} },
  { ["lhs"]={0x01,0x02},  ["rhs"]={0xFF}, ["result"]={0x01, 0x00, 0xFE} },
  { ["lhs"]={0x15,0x2D,0x02,0xC7,0xE1,0x4A,0xF6,0x80,0x00,0x00},  ["rhs"]={0x0A}, ["result"]={0x01, 0x00, 0xFE} },
  { ["lhs"]={0x15,0x2D,0x02,0xC7,0xE1,0x4A,0xF6,0x80,0x00,0x00},  ["rhs"]={0x64}, ["result"]={0x01, 0x00, 0xFE} },
  { ["lhs"]={0x15,0x2D,0x02,0xC7,0xE1,0x4A,0xF6,0x80,0x00,0x00},  ["rhs"]={0x03, 0xE8}, ["result"]={0x01, 0x00, 0xFE} }
}

local testVectorIEEE754 = 
{
  {["lhs"]="3F800000",	["decimal"]="1.0",					        ["trim"] = utils.NO_TRAILING_0, ["result"]={0x15,0x2D,0x02,0xC7,0xE1,0x4A,0xF6,0x80,0x00,0x00}},
  {["lhs"]="41000000",	["decimal"]="8.0",					        ["trim"] = utils.NO_TRAILING_0, ["result"]={0xA9,0x68,0x16,0x3F,0x0A,0x57,0xB4,0x00,0x00,0x00}},
  {["lhs"]="462B1800",	["decimal"]="10950.0",				      ["trim"] = utils.NO_TRAILING_0, ["result"]={0x2A,0xC6}},
  {["lhs"]="40800000",	["decimal"]="4.0",					        ["trim"] = utils.NO_TRAILING_0, ["result"]={4}},
  {["lhs"]="42040000",	["decimal"]="33.0",				          ["trim"] = utils.NO_TRAILING_0, ["result"]={33}},
  {["lhs"]="46FD8A00",	["decimal"]="32453.0",				      ["trim"] = utils.NO_TRAILING_0, ["result"]={0x7E,0xC5}},
  {["lhs"]="42740000",	["decimal"]="61.0",				          ["trim"] = utils.NO_TRAILING_0, ["result"]={61}},
  {["lhs"]="471DF200",	["decimal"]="40434.0",				      ["trim"] = utils.NO_TRAILING_0, ["result"]={0x9D,0xF2}},
  {["lhs"]="41C3FA36",  ["decimal"]="24.49717330932617",    ["trim"] = 14,                	["result"]={0xDE,0xCC,0xED,0x21,0x8B,0x8D}},
  {["lhs"]="C243BF60",	["decimal"]="-48.9368896484375",    ["trim"] = utils.NO_TRAILING_0,	["result"]={0x01,0xBD,0x14,0x13,0x3D,0x34,0x17}},
  {["lhs"]="C14D20D2",	["decimal"]="-12.820512771606445",  ["trim"] = 15,	                ["result"]={0x74,0x9A,0x15,0x18,0x8C,0xE0}},
  {["lhs"]="BFE03EAC",	["decimal"]="-1.7519125938415527",  ["trim"] = 16,	                ["result"]={0x9F,0x55,0xE4,0xC8,0x89,0x5B}},
  {["lhs"]="3C4BB600",	["decimal"]="0.012433528900146484", ["trim"] = 18,	                ["result"]={0x71,0x15,0x10,0xBB,0xE5,0xF8}},
  {["lhs"]="3B8EAB93",	["decimal"]="0.00435394933447241",  ["trim"] = 17,	                ["result"]={0x01,0x8B,0xFD,0x48,0x58,0x5A,0x49}},
  {["lhs"]="00000000",	["decimal"]="0.0",				          ["trim"] = utils.NO_TRAILING_0, ["result"]={0}},
  {["lhs"]="BF843FE6",	["decimal"]="-1.033200025558471",   ["trim"] = 15,                  ["result"]={0x5D,0xF8,0x10,0x0C,0xEF,0xC7}},
  {["lhs"]="4007E69A",	["decimal"]="2.1234498023986816",		["trim"] = 16,                  ["result"]={0x03,0x3D,0x79}},
  {["lhs"]="4047E69B",	["decimal"]="3.1234500408172607",		["trim"] = 16,                  ["result"]={0x04,0xC4,0x19}},
  {["lhs"]="4094F032",	["decimal"]="4.65432071685791",			["trim"] = 14,                  ["result"]={0x47,0x04,0xF1}}
}

local function printBytesFromTable(theTableOfBytes)
	if( (nil ~= theTableOfBytes) and (type(theTableOfBytes) == "table")) then
		local length = #theTableOfBytes
		local index = 1
		local strVal = "Table: "
		while( index <= length ) do
			strVal = strVal .. string.format("0x%02X, ", theTableOfBytes[index])
			index = index + 1
		end
    
    utils.dbSafePrint(1, strVal)
	end
end

local function compareArray(lhs, rhs)
  local hasMore = true
  local lhsIndex, rhsIndex, lhsElement, rhsElement = nil
  local isMatch = true
  
  while(true == hasMore) do
    lhsIndex, lhsElement = next(lhs, lhsIndex, lhsElement)
    rhsIndex, rhsElement = next(rhs, rhsIndex, rhsElement)
    
    if( (nil == lhsElement) or (nil == rhsElement) ) then
      hasMore = false
    else
      if( lhsElement ~= rhsElement ) then
        isMatch = false
        hasMore = false
      end
    end
  end
  
  return isMatch
end

local function testGeneric(testVector, functionPtr)
  local index, object = nil
  local hasMore = true
  local testResult = false
  
  while(true == hasMore) do
    index, object = next(testVector, index, object)
    
    if( nil == object ) then
      hasMore = false
    else
      functionPtr(object["lhs"], object["rhs"])
      if( true == compareArray(object["lhs"], object["result"]) ) then
        testResult = true
        utils.dbSafePrint(1,"test step succeeded. Step: ", index)
      else
        -- figure something out. print error maybe
        utils.dbSafePrint(1,"test step failed. Step: ", index)
        printBytesFromTable(object["lhs"])
        utils.dbSafePrint(1,"\n")
        printBytesFromTable(object["result"])
      end
    end
  end
  
  return testResult
end

local function testGenericTrio(testVector, functionPtr)
  local index, object = nil
  local hasMore = true
  local testResult = false
  
  while(true == hasMore) do
    index, object = next(testVector, index, object)
    
    if( nil == object ) then
      hasMore = false
    else
      local result = {}
      result = functionPtr(object["lhs"], object["rhs"])
      if( true == compareArray(result, object["result"]) ) then
        testResult = true
        utils.dbSafePrint(1,"test step succeeded. Step: ", index)
      else
        -- figure something out. print error maybe
        utils.dbSafePrint(1,"test step failed. Step: ", index)
      end
    end
  end
  
  return testResult
end


local function testGenericSingle(testVector, functionPtr)
  local index, object = nil
  local hasMore = true
  local testResult = false
  
  while(true == hasMore) do
    index, object = next(testVector, index, object)
    
    if( nil == object ) then
      hasMore = false
    else
      local result = {}
      result = functionPtr(object["lhs"], object["trim"])
      if( result == object["decimal"] ) then
        testResult = true
        utils.dbSafePrint(1,"test step succeeded. Step: ", index)
      else
        -- figure something out. print error maybe
        utils.dbSafePrint(1,"test step failed. Step: " , index)
        utils.dbSafePrint(1,"\n expected: " .. object["decimal"] .. " received " .. result)
      end
    end
  end
  
  return testResult
end

---
--
local function testAdd()
  local index, object = nil
  local hasMore = true
  local testResult = false
  
  while(true == hasMore) do
    index, object = next(testVectorAddition, index, object)
    
    if( nil == object ) then
      hasMore = false
    else
      utils.ArrayAdd(object["lhs"], object["rhs"], object["start"])
      if( true == compareArray(object["lhs"], object["result"]) ) then
        testResult = true
        utils.dbSafePrint(1,"test step succeeded. Step: ", index)
      else
        -- figure something out. print error maybe
        utils.dbSafePrint(1,"test step failed. Step: ", index)
      end
    end
  end
  
  return testResult
end

local function testMul()
  return testGenericTrio(testVectorMul, utils.ArrayMul)
end

local function testAddN()
  return testGeneric(testVectorAdditionN, utils.ArrayAddN)
end

local function testIEEE754ToString()
  return testGenericSingle(testVectorIEEE754,utils.IEEE754_ToString)
end

local function testPrintIEEE754Consts()
	local index, object = nil
	local hasMore = true
	
	while( true == hasMore ) do
		index, object = next(utils.IEEE754_BITS, index)
		
		if( nil == object ) then
			hasMore = false
		else
			utils.dbSafePrint(1, object)
		end
	end
end

local function stringIntToByteArray(strNum)
	local result = {0x00}
	
	if( nil ~= strNum ) then
		local strIndex = 1
		local strLen = string.len(strNum)
		local digit = 0
		
		while( strIndex < strLen ) do
			digit = string.sub(strNum, strIndex, strIndex)
			strIndex = strIndex + 1
			utils.ArrayAdd(result, tonumber(digit), #result)
			result = utils.ArrayMul(result, {10});
		end
	end
	
	return result
end

local function convertIEEE754StrToArrayOfByte()
	local index, object = nil
	local hasMore = true
	
	while( true == hasMore ) do
		index, object = next(utils.IEEE754_BITS, index)
		
		if( nil == object ) then
			hasMore = false
		else
			object["byte_val"] = stringIntToByteArray(object[utils.IEEE754_STRING])
			utils.dbSafePrint(1,object[utils.IEEE754_STRING])
			printBytesFromTable(object[utils.IEEE754_BYTES])
			utils.dbSafePrint(1,"\n\n")
		end
	end
end

local function testIEEE754ConstsAddition()
	local index, object = nil
	local hasMore = true
	local additionTable = 
		{ 
			100000000000000000000000,
			150000000000000000000000,
			175000000000000000000000,
			187500000000000000000000,
			193750000000000000000000,
			196875000000000000000000,
			198437500000000000000000,
			199218750000000000000000,
			199609375000000000000000,
			199804687500000000000000,
			199902343750000000000000,
			199951171875000000000000,
			199975585937500000000000,
			199987792968750000000000,
			199993896484375000000000,
			199996948242187500000000,
			199998474121093750000000,
			199999237060546875000000,
			199999618530273437500000,
			199999809265136718750000,
			199999904632568359375000,
			199999952316284179687500,
			199999976158142089843750,
			199999988079071044921875 
		}

	local result = 0
	
	while( true == hasMore ) do
		index, object = next(utils.IEEE754_BITS, index)
		
		if( nil == object ) then
			hasMore = false
		else
			result = result + object
			utils.dbSafePrint(1, object)
      if result ~= additionTable[index] then
        utils.dbSafePrint(1,"FAILED MATCH!")
      end
		end
	end
end
---
--
function main()
	local testResult = true
	local today = os.time()
	utils.dbSafePrint(1, "Test started. ", today, ", ", os.date("%x", today))
	
--	convertIEEE754StrToArrayOfByte()
--	testPrintIEEE754Consts()
  
--	testIEEE754ConstsAddition()
  
--  if( false == testAdd() ) then
--  end

 -- if( false == testAddN() ) then
 -- end

 -- if( false == testMul() ) then
--  end
  testIEEE754ToString()
  
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
