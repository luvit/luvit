local serial = require'serial'
local timer = require'timer'

--I use virtual port download from http://freevirtualserialports.com/

local com = serial.open('\\.\\COM1',function(self)
    print('opened',self)
end)

local com1 = serial.open('\\.\\COM2',function(self)
    print('opened2',self)
end)

com:read(function(self,data)
    print('COM  RECV:',data)
end)
    
com:on('error',function(err)
    print('ERROR0:',err)
end)

com:on('end',function(err)
    print('END:',err)
end)

R='ABCD'
com:write(R)

com1:write(R,function(...)
    com1:read(function(self,data)
        print('COM1 RECV:',data)
    end)
end)
com1:on('error',function(err)
    print('ERROR1:',err)
end)

local i = 0

local interval = timer.setInterval(200, function ()
  i=i+1
  if i>10 then
      com1:destroy(nil,function(...)
        print('com1 destroyed',...)
          com:destroy(nil,function(...)
            print('com destroyed',...)
            os.exit()
          end)

      end)
    else
        com1:write(R)
    end
end)
