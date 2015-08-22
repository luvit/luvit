local uv = require('uv')
local timer = require('timer')
local utils = require('utils')
local Emitter = require('core').Emitter
local apdu = require('./apdu')

local Modbus = Emitter:extend()

function Modbus:initialize(serial,title)
    self._serial = serial
    self._title = title
end

function Modbus:destroy()
    self._serial:destroy()
end

function Modbus:query(sid,func,data)
    assert(type(sid)=='number' and (sid>=0 and sid<256))
    assert(type(func)=='number' and (func>0 and func<=16))
    data = data or ''
    assert(#data<=252)
    local Q = apdu.buildADU(sid,func,data)
    self._serial:write(Q,function() 
        if self.debug then print('QUERY:',openssl.hex(Q)) end
    end)
    self._serial:read(function(com,R)
      if R then
        if self.debug then  print('REPLY:',openssl.hex(R)) end
        local _1,_2,data,crc = string.unpack('BBs1H',R)
        assert(_1==sid)
        assert(_2==func)
        if self.debug then
            print('CRC  :',string.format('%04x',crc))
            print('DATA :',openssl.hex(data))
        end
        self:emit('data',data)
      end
    end)
end

function Modbus:readCoils(address,data)
    self:query(address,0x01, data)
end

function Modbus:readDiscreteInputs(sid,addr,len)
    self:query(sid,0x02, string.pack('>HH',addr,len))
end

function Modbus:readHoldingRegisters(sid,addr,len)
    self:query(sid,0x03, string.pack('>HH',addr,len))
end

function Modbus:readInputRegisters(sid,addr,len)
    self:query(sid,0x04, string.pack('>HH',addr,len))
end

function Modbus:writeMultipleCoils(sid,address,nbvalues,values)
end

function Modbus:writeMultipleRegister(sid,address,values)
end

function Modbus:writeSingleCoil(sid,address,value)
    self:query(address,0x05, data)
end

function Modbus:writeSingleRegister(sid,address,value)
    self:query(address,0x06, data)
end

function Modbus:customRequest(req,sid,payload)
end

return Modbus
