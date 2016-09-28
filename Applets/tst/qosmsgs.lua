
---------------------------------------------------------------------------------------------------
local function toInt8Char(num)
    local b = num
    if num > 127 or num <-128 then
        utils.dbSafePrint(1, "ERROR:  number supplied to toInt8Char out of range")
    end
    
    if num < 0 then -- return the 2s complement
        b = 256 - math.abs(num)
    end
    
    return string.char(b)
end

---------------------------------------------------------------------------------------------------
local function msb(num)
    local n = math.floor(num/256)
    return n
end

---------------------------------------------------------------------------------------------------
local function lsb(num)
    local n = num - (msb(num) * 256)
    return n
end

---------------------------------------------------------------------------------------------------
QosRouterZm = {}
QosRouterZm.new = function(hostEid)
    local self = {}
    
    self.hostEid = hostEid
    self.message = {}
    self.message["SOURCE"]  = "Router"
    self.message.metereid   = hostEid
    self.message.cmdstr     = "Response"
    self.message.data       = ""
    
    ---------------------------------------------------------------------------------------------------
    -- connectedEid is the eid of a connected device in hex string format.
    -- It must be inserted into the message in byte format.
    -- lqi and rssi are numbers which must be <= 255 and are each inserted as a byte
    -- make a dummy zigbee message from a router
    -- TODO:  dont know yet what exactly the data looks like
    -- Is it just a running avg, or are there timestamps ?
    -- Assume for now the info is in zm.data and is of the form:
    -- <farEid1 8 bytes><rssi.min.val1 int8><rssi.max.val1 int8><rssi.avg.val1><lqi.min.val1 uint8><lqi.max.val1 uint8><lqi.avg.val1 uint8>
    -- <farEid2 8 bytes><rssi.min.val2 int8>... etc
    self.add = function(connectedEid, rssi_min, rssi_avg, rssi_max, lqi_min, lqi_avg, lqi_max, count)
        if string.len(connectedEid) ~= 16 then
            utils.dbSafePrint(1, "ERROR:  connectedEid wrong length")
            return
        end
        
        if not (rssi_min <= rssi_avg and rssi_avg <= rssi_max) then
            utils.dbSafePrint(1, "ERROR:  RSSI input values incorrect")
            return
        end
 
        if not (lqi_min <= lqi_avg and lqi_avg <= lqi_max) then
            utils.dbSafePrint(1, "ERROR:  RSSI input values incorrect")
            return
        end
 
        local b, s, idx
        for i = 0, 7 do
            idx = (i * 2) + 1
            s = string.sub(connectedEid, idx, idx + 1)
            b = string.char(tonumber(s, 16))
            self.message.data = self.message.data .. b
        end
        
        self.message.data = self.message.data .. toInt8Char(rssi_min)
        self.message.data = self.message.data .. toInt8Char(rssi_avg)
        self.message.data = self.message.data .. toInt8Char(rssi_max)
        self.message.data = self.message.data .. string.char(lqi_min)
        self.message.data = self.message.data .. string.char(lqi_avg)
        self.message.data = self.message.data .. string.char(lqi_max)
        self.message.data = self.message.data .. string.char(msb(count))
        self.message.data = self.message.data .. string.char(lsb(count))
    end
 
    ---------------------------------------------------------------------------------------------------
    self._printMessageBytes = function()
        local length = string.len(self.message.data)
        local s = ""
        for b = 1, length do
            if s ~= "" then
                s = s .. ","
            end
            s = s .. string.format("%3d", string.byte(string.sub(self.message.data, b, b)))
        end
        
        utils.dbSafePrint(1, "Message bytes ", s)
    end 
 
    ---------------------------------------------------------------------------------------------------
    self.get = function()
        self._printMessageBytes()
        return self.message
    end
 
    return self
end

---------------------------------------------------------------------------------------------------
QosLocalMsg = {}
QosLocalMsg.new = function()
    local self = {}
       
    ---------------------------------------------------------------------------------------------------
    self.make = function(eid, rssi, lqi)
        if string.len(eid) ~= 16 then
            utils.dbSafePrint(1, "ERROR:  connectedEid wrong length")
        end
        
        local msg = {}
        msg["TYPE"]   = "NCP"
        msg["INFO"]   = "QOS"
        msg["SOURCE"] = "Local"
        msg["EID"]    = eid
        msg["RSSI"]   = rssi
        msg["LQI"]    = lqi
        
        return msg
    end
 
    return self
end

QosMsgTest = {}

---------------------------------------------------------------------------------------------------
QosMsgTest.routerMsgTest = function()
    local s = Stats.new(1)
    local rm = QosRouterZm.new("0000000000000001")
    --                   RSSI  min    avg   max LQI min avg max count
    rm.add("D000000000000001", -3,    -2,   -1,     10, 12, 14, 5)
    rm.add("D000000000000002", -6,    -5,   -4,     11, 13, 15, 256)
    rm.add("D000000000000003", -9,    -8,   -7,     20, 22, 24, 512)
    s.handleZigbeeMsg(rm.get())
    socket.sleep(2)
    
    rm = QosRouterZm.new("0000000000000001")
    rm.add("D000000000000001", -30,  -10,   -5,  100, 105, 110, 6)
    
    s.handleZigbeeMsg(rm.get())
    --s.print()
    s.report()
    utils.dbSafePrint(1, "  DONE  ")
end

---------------------------------------------------------------------------------------------------
QosMsgTest.localMsgTest = function()
    local context = 1
    local s = Stats.new(context)
    local m = QosLocalMsg.new()
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