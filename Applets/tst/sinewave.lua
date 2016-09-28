--------------------------------------------------------------------------------------------------
-- Purpose: Sinewave generator
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
if not onWindows then -- select real modules
    defs  = require "src.defines"
    local fme = require(defs.module.fme)
else
    defs  = require "defines"
    stats = require(defs.module.stats)
end

local utils   = require(defs.module.utils)   

local PI = 3.1415926

---------------------------------------------------------------------------------------------------
-- Sine Wave generator class.
-- Generates a sine wave between min and max, with a value supplied in degrees.
-- Equations:
-- yMultiplier = (max - min) / 2
-- result = yMultiplier * sin(x) + yOffset
-- At the minimum:
-- min = (yMultiplier * -1) + yOffset = yOffset - yMultiplier
-- so:
-- yOffset = min + yMultiplier 
-- 
-- degreesOffset is a positive number which shifts the curve.
-- The value function will return the sine value for the given angle plus degreesOffset.
local SineWave = {}
SineWave.new = function(min, max, degreesOffset)
    local self = {}
    
    self.min            = min
    self.max            = max
    if degreesOffset ~= nil then
        self.degreesOffset = degreesOffset
    else
        self.degreesOffset = 0
    end
    self.range          = self.max - self.min
    self.yMultiplier    = self.range/2  
    self.yOffset        = min + self.yMultiplier
    
    -----------------------------------------------------------------------------------------------
    self.value = function(degrees)
        local radians = (2 * PI)*((degrees + self.degreesOffset)/360)
        return self.yMultiplier * math.sin(radians) + self.yOffset
    end
 
    -----------------------------------------------------------------------------------------------
    -- 
    self.validate = function(value)
        if math.fmod (value, 10) ~= 0 then
            utils.dbSafePrint("ERROR:  angle value not divisible by 10")
            os.exit(-1)
        end
    end
 
    -----------------------------------------------------------------------------------------------
    -- include samples on the start boundary but but not the end boundary
    self.average = function(startDegrees, endDegrees, increments)
        local sum = 0
        local count = 0
        for i = startDegrees, endDegrees, increments do
            if i < endDegrees then 
                sum = sum + self.value(i)
                count = count + 1
            end
        end
        
        local average = sum/count
        
        return average
    end
 
    -----------------------------------------------------------------------------------------------
    -- include samples on the start boundary but but not the end boundary
    self.lastMaxPos = function(startDegrees, endDegrees)
        local n = 0 
        local angle, pos
        while true do
            angle = 90 + 360*n
            if angle >= startDegrees then
                if angle < endDegrees then
                    pos = angle
                else
                    break
                end
            end
            n = n + 1
        end
            
        return pos
    end
 
    -----------------------------------------------------------------------------------------------
    -- include samples on the start boundary but but not the end boundary
    -- startDegrees & endDegrees must be divisible by 10
    self.lastMinPos = function(startDegrees, endDegrees)
        local n = 0 
        local angle, pos
        while true do
            angle = 180 + 360*n
            if angle >= startDegrees then
                if angle < endDegrees then
                    pos = angle
                else
                    break
                end
            end
            n = n + 1
        end
            
        return pos
    end
 
    return self
end

---------------------------------------------------------------------------------------------------
function sineTest()
    local s = SineWave.new(0, 10)
    local degrees
    for degrees = 0, 1000, 10 do
        local value = string.format("%3.1f", s.value(degrees))
        print(degrees, "  ", value)
    end
    
    s.average(0, 460, 10)
    s.lastMaxPos(0, 460)
    s.lastMinPos(0, 600)
end