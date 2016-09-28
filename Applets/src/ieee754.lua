---------------------------------------------------------------------------------------------------
-- Purpose: defines
--
-- Author: 
--
-- Details:
--
-- Copyright Statement:
-- Copyright © 2015 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

-- Taken from Programming in Lua, 2nd Ed, p142
-- means that this is used as a module:
-- local utils = require "utils"
-- utils.dbPrint(...)
local modname = ...
local M = {}
_G[modname] = M
package.loaded[modname] = M
---------------------------------------------------------------------------------------------------
-- Function get32BitIEEE754
-- Support for IEEE754 32-Bit Floating point 
-- Returns Floating point number 
---------------------------------------------------------------------------------------------------
function M.get32BitIEEE754(hexstr) 
  
  local b1,b2,b3,b4
  local exponent 
  local mantissa
  b1= tonumber(string.sub(hexstr,1,2),16)
  b2= tonumber(string.sub(hexstr,3,4),16)
  b3= tonumber(string.sub(hexstr,5,6),16)
  b4= tonumber(string.sub(hexstr,7,8),16)
  exponent = (b1 % 0x80) * 0x02 + math.floor(b2 / 0x80)
  mantissa = math.ldexp(((b2 % 0x80) * 0x100 + b3) * 0x100 + b4, -23)
  if exponent == 0xFF then
    if mantissa > 0 then
      return 0
    else
      mantissa = math.huge
      exponent = 0x7F
    end
  elseif exponent > 0 then
    mantissa = mantissa + 1
  else
    exponent = exponent + 1
  end
  if b1 >= 0x80 then
    mantissa = -mantissa
  end
  return ( math.ldexp(mantissa, exponent - 0x7F) )

end

----------------------------------------------------------------------------------------------------
-- Function makeSingleprecisionFP
-- Param 
-- IEEE754 floating point number
-- Returns Single precision floating point as string
----------------------------------------------------------------------------------------------------
function M.makeSingleprecisionFP(fpnumber)
 
  -- As we dont do the roundig off , we send 5 decimal points. 
  local fp = string.format("%f",fpnumber)
  local pos = string.find ( fp,"%.")
  local len = string.len( fp )
  if ( (len - pos) >= 5 )  then
    return ( string.sub ( fp, 1, ( pos + 5 ) ) )
  elseif ( ((len - pos) > 0) and ((len - pos) < 5) ) then
    return ( string.sub ( fp,1,(pos + ( len - pos ) ) ) )
  else
    return ( fp .. ".0" )
  end

end

---------------------------------------------------------------------------------------------------
-- Function get32BitIEEE754Hexstr
-- Support for IEEE754 32-Bit Floating point 
-- Returns Floating point number 
---------------------------------------------------------------------------------------------------
function  M.get32BitIEEE754Hexstr(number)
    if number == 0 then
        return "00000000"
    elseif number ~= number then
        return "FFFFFFFF"
    else
        local sign = 0x00
        if number < 0 then
            sign = 0x80
            number = -number
        end
        local mantissa, exponent = math.frexp(number)
        exponent = exponent + 0x7F
        if exponent <= 0 then
            mantissa = math.ldexp(mantissa, exponent - 1)
            exponent = 0
        elseif exponent > 0 then
            if exponent >= 0xFF then
                return string.char(sign + 0x7F, 0x80, 0x00, 0x00)
            elseif exponent == 1 then
                exponent = 0
            else
                mantissa = mantissa * 2 - 1
                exponent = exponent - 1
            end
        end
        mantissa = math.floor(math.ldexp(mantissa, 23) + 0.5)
        return string.format("%02x",sign + math.floor(exponent / 2) ) ..
               string.format("%02x", (exponent % 2) * 0x80 + math.floor(mantissa / 0x10000)) ..
               string.format("%02x", math.floor(mantissa / 0x100) % 0x100) ..
               string.format("%02x", mantissa % 0x100)
    end
end
