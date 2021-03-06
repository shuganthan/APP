-- --------------------------------------------------------------------------------------------
-- Purpose: Modbus Lua Application:  defines
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
-- --------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT")


local T = {}

local modname = ...
local T = {}
_G[modname] = T
package.loaded[modname] = T

T.module = {}

T.module.os               = "os"
T.module.fme              = "fme"
if not onWindows then
  T.module.messagecenter    = "src.messagecenter"
  T.module.json             = "dkjson.dkjson"
  T.module.ieee754          = "src.ieee754"
else
  T.module.messagecenter    = "messagecenter"
  T.module.json             = "dkjson"
  T.module.ieee754          = "ieee754"
end 


-- -------------------------------------------------------------------------------------------
-- App Version
-- -------------------------------------------------------------------------------------------
T.LUA_APPLICATION_VERSION       = "AppletVersionPH" -- Written by script into bundle
T.printAlive                    = 3600 
T.DATA_RX_TIMEOUT               = 300
T.INFORM_INVALID_PDU            = 5
T.THREEGNIC_TEMP                = "/flash/threegnictemp"
T.THREEGNIC_PRSR                = "/flash/threegnicprsr"
T.THREEGNIC_SMPI                = "/flash/threegnicsmpi"
T.THREEGNIC_UPLI                = "/flash/threegnicupli"
-- -------------------------------------------------------------------------------------------
-- Switch side message IDs
-- ------------------------------------------------------------------------------------------
T.SEND_DATA                    = 1
T.LORA_PAYLOAD                 = 2
T.SEND_APP_ALERT               = 3
T.GNIC_PAYLOAD                 = 4
T.SET_CONFIG_TEMPERATURE       = 5
T.SET_CONFIG_PRESSURE          = 6
T.SET_CONFIG_SAMPLING_INTERVAL = 7
T.SET_CONFIG_UPLOAD_INTERVAL   = 8
T.GNIC_ALERT                   = 9
T.READ_FLOW_DATA               = 10
T.TANCY_ALERT                  = 11
T.SET_TANCY_CONFIG             = 12
-- --------------------------------------------------------------------------------------------
-- Message id to message name
-- --------------------------------------------------------------------------------------------
T.name = {}
T.name[T.SEND_DATA]                    = "SEND_DATA"
T.name[T.LORA_PAYLOAD]                 = "LORA_PAYLOAD"
T.name[T.SEND_APP_ALERT]               = "SEND_APP_ALERT"
T.name[T.GNIC_PAYLOAD]                 = "GNIC_PAYLOAD"
T.name[T.SET_CONFIG_TEMPERATURE]       = "SET_CONFIG_TEMPERATURE"
T.name[T.SET_CONFIG_PRESSURE]          = "SET_CONFIG_PRESSURE"
T.name[T.SET_CONFIG_SAMPLING_INTERVAL] = "SET_CONFIG_SAMPLING_INTERVAL"
T.name[T.SET_CONFIG_UPLOAD_INTERVAL]   = "SET_CONFIG_UPLOAD_INTERVAL"
T.name[T.GNIC_ALERT]                   = "GNIC_ALERT"
T.name[T.READ_FLOW_DATA]               = "READ_FLOW_DATA"
T.name[T.TANCY_ALERT]                  = "TANCY_ALERT"
T.name[T.SET_TANCY_CONFIG]             = "SET_TANCY_CONFIG" 

-- --------------------------------------------------------------------------------------------
-- ALERT MAPPING TABLE
-- --------------------------------------------------------------------------------------------
T.DATA_RX_TIMED_OUT_ERROR    = 1
T.INVALID_PDU_ERROR          = 2

-- -------------------------------------------------------------------------------------------
-- APP ALERT ID`s 
-- --------------------------------------------------------------------------------------------
T.alert = {}
T.alert[T.DATA_RX_TIMED_OUT_ERROR] = "DATA_RX_TIMED_OUT_ERROR"
T.alert[T.INVALID_PDU_ERROR ]      = "INVALID_PDU_ERROR"

-----------------------------------------------------------------------------------------------
---- FCP Related
-------------------------------------------------------------------------------------------------
-- Flags
T.FLAG_FRAMETYPE_RESP                           = 0x08
T.FLAG_RESP_REQ                                 = 0x04
T.FLAG_ACK_REQ                                  = 0x02
T.FLAG_DUP                                      = 0x01
-- Other
T.RESPONSE_OK                                   = 0
T.RESPONSE_ANYERR                               = 0xFFFFFFFF
T.RESULT_CODE                                   = "result_code"
T.ERROR_DETAILS                                 = "error_details"
T.TIMEOUT_STRING                                = "Timeout"
T.PARAM_MISSING                                 = "FCP Parameter Missing"

-- ---------------------------------------------------------------------------------------------
-- Seperator 
-- ---------------------------------------------------------------------------------------------
T.seperatorEqual = string.rep("=",90)

-- ---------------------------------------------------------------------------------------------
-- SIMULATION
-- ---------------------------------------------------------------------------------------------
T.simOn = 0 -- 1 IS ENABLE & 0 IS DISABLE 
