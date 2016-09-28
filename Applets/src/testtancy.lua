payload = [=[57d788840203184110000040f0fc46000000000000000041a0000042caa600baa257d788840203184110000040f0fc46000000000000000041a0000042caa600baa2]=]

print ( string.len(payload) )

local  tstamp = ''
local  flow   = ''
local  sflow  = ''
local  temp   = ''
local  vol1   = ''
local  vol2   = ''
local  pressure = ''
local idx = 1
for i=1,2 do
    
    tstamp = string.sub(payload, idx , idx+7 )
    idx = idx + 8
    -- skip modbus header
    idx = idx + 2 + 2 + 2
    vol1   = string.sub(payload,idx,idx+7 )
    idx = idx + 8
    vol2 = string.sub ( payload,idx ,idx+7 )
    idx = idx + 8
    sflow = string.sub ( payload,idx ,idx+7 )
    idx = idx + 8
    flow = string.sub ( payload,idx ,idx+7 )
    idx = idx + 8
    temp = string.sub ( payload,idx ,idx+7 )
    idx = idx + 8
    pressure = string.sub ( payload,idx ,idx+7)
    idx = idx + 8
    -- skip crc 
    idx = idx + 4
    print ( tstamp, vol1, vol2, sflow, flow, temp, pressure )
end




