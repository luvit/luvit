local uv = require'uv'
local ffi = require'ffi'

local device = require'device'
local const = require'./const'
local Device = device.Device

require'./declear'

ffi.cdef([[
typedef unsigned short WORD;
typedef unsigned long DWORD;
typedef unsigned char BYTE;
typedef int BOOL;
typedef void* HANDLE;
typedef struct _DCB {
  DWORD DCBlength;
  DWORD BaudRate;
  DWORD fBinary  :1;
  DWORD fParity  :1;
  DWORD fOutxCtsFlow  :1;
  DWORD fOutxDsrFlow  :1;
  DWORD fDtrControl  :2;
  DWORD fDsrSensitivity  :1;
  DWORD fTXContinueOnXoff  :1;
  DWORD fOutX  :1;
  DWORD fInX  :1;
  DWORD fErrorChar  :1;
  DWORD fNull  :1;
  DWORD fRtsControl  :2;
  DWORD fAbortOnError  :1;
  DWORD fDummy2  :17;
  WORD  wReserved;
  WORD  XonLim;
  WORD  XoffLim;
  BYTE  ByteSize;
  BYTE  Parity;
  BYTE  StopBits;
  char  XonChar;
  char  XoffChar;
  char  ErrorChar;
  char  EofChar;
  char  EvtChar;
  WORD  wReserved1;
} DCB, *LPDCB;

BOOL SetCommState(
  HANDLE hFile,
  LPDCB  lpDCB
);
BOOL GetCommState(
  HANDLE hFile,
  LPDCB  lpDCB
);
BOOL BuildCommDCBA(
  const char* lpDef,
  LPDCB   lpDCB
);
BOOL SetCommTimeouts(
  HANDLE         hFile,
  LPCOMMTIMEOUTS lpCommTimeouts
);
BOOL GetCommTimeouts(
  HANDLE         hFile,
  LPCOMMTIMEOUTS lpCommTimeouts
);
]])

local Serial = Device:extend()

function Serial:initialize(devname, options, flags)
  self.options = options
  self.debug = options.debug
  self.options.debug = nil

  Device.initialize(self,devname,flags)
end

local function printDCB(dcb)
  print('DCBlength          ',dcb[0].DCBlength);
  print('BaudRate           ',dcb[0].BaudRate);
  
  print('fBinary            ',dcb[0].fBinary);
  print('fParity            ',dcb[0].fParity);
  print('fOutxCtsFlow       ',dcb[0].fOutxCtsFlow);
  print('fOutxDsrFlow       ',dcb[0].fOutxDsrFlow);
  print('fDtrControl        ',dcb[0].fDtrControl);
  print('fDsrSensitivity    ',dcb[0].fDsrSensitivity);
  print('fTXContinueOnXoff  ',dcb[0].fTXContinueOnXoff);
  print('fOutX              ',dcb[0].fOutX);
  print('fInX               ',dcb[0].fInX);
  print('fErrorChar         ',dcb[0].fErrorChar);
  
  print('fNull              ',dcb[0].fNull);
  print('fRtsControl        ',dcb[0].fRtsControl);
  print('fAbortOnError      ',dcb[0].fAbortOnError);
  print('fDummy2            ',dcb[0].fDummy2);
  print('XonLim             ',dcb[0].XonLim);
  print('XoffLim            ',dcb[0].XoffLim);
  
  print('ByteSize           ',dcb[0].ByteSize);
  print('Parity             ',dcb[0].Parity);
  print('StopBits           ',dcb[0].StopBits);
  print('XonChar            ',dcb[0].XonChar);
  print('XoffChar           ',dcb[0].XoffChar);
  print('ErrorChar          ',dcb[0].ErrorChar);
  print('EofChar            ',dcb[0].EofChar);
  print('EvtChar            ',dcb[0].EvtChar);
end

local function printTimeouts(outs)
  print('ReadIntervalTimeout        :',outs[0].ReadIntervalTimeout);
  print('ReadTotalTimeoutMultiplier :',outs[0].ReadTotalTimeoutMultiplier);
  print('ReadTotalTimeoutConstant   :',outs[0].ReadTotalTimeoutConstant);
  print('WriteTotalTimeoutMultiplier:',outs[0].WriteTotalTimeoutMultiplier);
  print('WriteTotalTimeoutConstant  :',outs[0].WriteTotalTimeoutConstant);
end

function Serial:open(callback)
  Device.open(self,function()
    local dcb = ffi.new('DCB[1]')
    --[[
         COMx[:][baud=b][parity=p][data=d][stop=s][to={on|off}][xon={on|off}]
                [odsr={on|off}][octs={on|off}][dtr={on|off|hs}]
                [rts={on|off|hs|tg}][idsr={on|off}]
    --]]
    local set = {}
    for k,v in pairs(self.options) do
      set[#set+1] = string.format('%s=%s',k,v)
    end
    set = table.concat(set, ' ')
    
    local h = ffi.cast('void*',self._fd)
    local ret = ffi.C.BuildCommDCBA(set,dcb)

    if(ret==1) then 
      ret = ffi.C.SetCommState(ffi.cast('void*',self._fd),dcb)
      assert(ret==1 or ffi.errno()==0)
      if self.debug then printDCB(dcb) end
      local outs = ffi.new('COMMTIMEOUTS[1]')
      ffi.fill(outs,0,ffi.sizeof(outs))
      ret = ffi.C.GetCommTimeouts(h,outs)
      assert(ret==1)
      if self.debug then printTimeouts(outs) end
      --[[
      outs[0].ReadIntervalTimeout = 10;
      outs[0].ReadTotalTimeoutMultiplier = 0;
      outs[0].ReadTotalTimeoutConstant = 0;
      outs[0].WriteTotalTimeoutMultiplier = 0;
      outs[0].WriteTotalTimeoutConstant = 0;

      ret = ffi.C.SetCommTimeouts(ffi.cast('void*',self._fd),outs)
      assert(ret==1)
      if self.debug then printTimeouts(outs) end
      --]]
    else
      error('serial BuildCommDCB fail with '
        ..string.format('0x%08x',ffi.errno()))
    end
    --[[ device_ioctl too lower for serial
    
    uv.stream_set_blocking(self.device,false)
    local baud = ffi.new('SERIAL_BAUD_RATE[1]')
    print('IOCTL_SERIAL_SET_BAUD_RATE',const.IOCTL_SERIAL_SET_BAUD_RATE)
    baud[0].BaudRate = const.SERIAL_BAUD_9600
    print(assert(uv.device_ioctl(self.device,const.IOCTL_SERIAL_SET_BAUD_RATE,
      ffi.string(baud, ffi.sizeof('SERIAL_BAUD_RATE[1]')))))
    
    local set = ffi.new('SERIAL_LINE_CONTROL[1]')
    set[0].StopBits = const.STOP_BIT_1
    set[0].Parity = const.NO_PARITY 
    set[0].WordLength = const.SERIAL_DATABITS_8
    print(assert(uv.device_ioctl(self.device,
      const.IOCTL_SERIAL_SET_LINE_CONTROL,
      ffi.string(set,ffi.sizeof('SERIAL_LINE_CONTROL[1]')))))
    --]]
    callback(self)
  end)
end

exports.Serial = Serial
