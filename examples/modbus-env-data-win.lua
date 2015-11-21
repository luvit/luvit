local serial = require'serial'
local timer = require'timer'
local Modbus = require'modbus'.modbus
local uv = require'uv'

local count = 5
local interval = 1*1000
local port = 'COM3'  --should change this
local opened

opened = assert(serial.open('\\.\\'..port,function(self)
  local len = 0x08*2
  local sid = 1
  local bus = Modbus:new(self,'demo-at-01')
  bus:readInputRegisters(sid,0,len)
  bus.debug = true

  bus:on('data',function(data)
    ----011f 018e 0000 0000 0000 0000 0000 03e7
    assert(#data==2*len)
    local _1,  _2,  _3,  _4,  _5,  _6, _7,  _8 = string.unpack('>HHHHHHHH',data)
    io.write('�����¶�:\t',_1/10,'\n')
    io.write('����ʪ��:\t',_2/10,'\n')
    io.write('�����¶�:\t',_3/10,'\n')
    io.write('����ʪ��:\t',_4/10,'\n')
    io.write('����ǿ��:\t',_5,'\n')
    io.write(' CO2Ũ��:\t',_6,'\n')
    io.write('    ��ѹ:\t',_7,'\n')
    io.write('�ɼ�����:\t',_8,'\n')
  end)
  local i = 0
  local tick
  tick  = timer.setInterval(interval, function ()
    if i>= count then 
      timer.clearInterval(tick)
      opened:destroy(nil,function(...) print(...) end)
      return
    end
    i=i+1
    bus:readInputRegisters(sid,0,len)    
  end)
end))

------------------------------------------------------------------------------

