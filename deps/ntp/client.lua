local dns = require('dns')
local dgram = require('dgram')
local timer = require('timer')

local Emitter = require'core'.Emitter
local os = os
--[[
local time = require'time'

local _SYSTEM_EPOCH = time.date(os.date('*t').year,1,1)
local _NTP_EPOCH = time.date(1900, 1, 1)
local NTP_DELTA = _SYSTEM_EPOCH - _NTP_EPOCH

local REF_ID_TABLE = {
        ["GOES"]=  "Geostationary Orbit Environment Satellite",
        ["GPS\0"]= "Global Position System",
        ["GAL\0"]= "Galileo Positioning System",
        ["PPS\0"]= "Generic pulse-per-second",
        ["IRIG"]=  "Inter-Range Instrumentation Group",
        ["WWVB"]=  "LF Radio WWVB Ft. Collins, CO 60 kHz",
        ["DCF\0"]= "LF Radio DCF77 Mainflingen, DE 77.5 kHz",
        ["HBG\0"]= "LF Radio HBG Prangins, HB 75 kHz",
        ["MSF\0"]= "LF Radio MSF Anthorn, UK 60 kHz",
        ["JJY\0"]= "LF Radio JJY Fukushima, JP 40 kHz, Saga, JP 60 kHz",
        ["LORC"]=  "MF Radio LORAN C station, 100 kHz",
        ["TDF\0"]= "MF Radio Allouis, FR 162 kHz",
        ["CHU\0"]= "HF Radio CHU Ottawa, Ontario",
        ["WWV\0"]= "HF Radio WWV Ft. Collins, CO",
        ["WWVH"]=  "HF Radio WWVH Kauai, HI",
        ["NIST"]=  "NIST telephone modem",
        ["ACTS"]=  "NIST telephone modem",
        ["USNO"]=  "USNO telephone modem",
        ["PTB\0"]= "European telephone modem",
        ["LOCL"]=  "uncalibrated local clock",
        ["CESM"]=  "calibrated Cesium clock",
        ["RBDM"]=  "calibrated Rubidium clock",
        ["OMEG"]=  "OMEGA radionavigation system",
        ["DCN\0"]= "DCN routing protocol",
        ["TSP\0"]= "TSP time protocol",
        ["DTS\0"]= "Digital Time Service",
        ["ATOM"]=  "Atomic clock (calibrated)",
        ["VLF\0"]= "VLF radio (OMEGA,, etc.)",
        ["1PPS"]=  "External 1 PPS input",
        ["FREE"]=  "(Internal clock)",
        ["INIT"]=  "(Initialization)",
        ["\0\0\0\0"]=   "NULL",
    }

local MODE_TABLE = {
        [0]= "reserved",
        [1]= "symmetric active",
        [2]= "symmetric passive",
        [3]= "client",
        [4]= "server",
        [5]= "broadcast",
        [6]= "reserved for NTP control messages",
        [7]= "reserved for private use",
    }
local LEAP_TABLE = {
        [0]= "no warning",
        [1]= "last minute of the day has 61 seconds",
        [2]= "last minute of the day has 59 seconds",
        [3]= "unknown (clock unsynchronized)",
    }
--]]

--[[
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |LI | VN  |Mode |    Stratum    |     Poll      |   Precision   |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                            根延迟                             |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                            根差量                             |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          参考标识符                           |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                          参考时间戳(64)                       |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                           原始时间戳(64)                      |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                           接受时间戳 (64)                     |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                          传送时间戳(64)                       |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                                                               |
      |                         认证符(可选项) (96)                   |
      |                                                               |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
--]]
local NTPClient = Emitter:extend()

local function getRequest()
    --First BYTE: LeapIndicator = 0 , VersionNum = 3 or 2 , Mode = 3 (Client Mode)
    --[[
    #NTP v2 Monlist Request : "0x17,x00,x03,x2a, x00"
    #NTP v3 Monlist Request : "0x1b,x00,x03,x2a, x00"
    --]]

    return string.char(
        0xE3, 0x00, 0x06, 0xEC,
           0,    0,    0,    0,
           0,    0,    0,    0,
           70,  82,   69,   69, --FREE (Internal clock)
        -- 参考时间戳(64)
           0,    0,    0,    0,
           0,    0,    0,    0,
        -- 原始时间戳(64)
           0,    0,    0,    0,
           0,    0,    0,    0,
        -- 接受时间戳 (64)
           0,    0,    0,    0,
           0,    0,    0,    0,
        -- 传送时间戳(64)
           0,    0,    0,    0,
           0,    0,    0,    0
	)
end

local function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end

function NTPClient:initialize(ntpserver, callback)
    self.ntpserver = assert(ntpserver) --"194.109.22.18"
    assert(type(callback)=='function')

    self.port = 123
	self.tz=get_timezone()
    self.request=getRequest()

    dns.resolve4(self.ntpserver, function(err, answers)
        if err then
            self:emit('error','dns ERROR')
        end
        for k,v in pairs(answers) do
            if v.type==dns.TYPE_A then
                self.server = v.address
                break
            end
        end

        self.socket = dgram.createSocket()
        self.socket:bind(self.port,'0.0.0.0')
        self.socket:on("message",function(msg,rinfo)
            self:emit('update',self:calc_stamp(msg:sub(41,44)))
        end)
        self.socket:on('error',function(...)
            self.emit('error',...)
        end)
        callback(self)
    end)
end

function NTPClient:calc_stamp(bytes)
	local highw,loww,ntpstamp
	highw = bytes:byte(1) * 256 + bytes:byte(2)
	loww = bytes:byte(3) * 256 + bytes:byte(4)
	ntpstamp=( highw * 65536 + loww ) + self.tz         -- NTP-stamp, seconds since 1.1.1900
	return ntpstamp - 1104494400 - 1104494400 		-- UNIX-timestamp, seconds since 1.1.1970
end

function NTPClient:query()
    if self.server then
        self.socket:send(self.request,self.port,self.server)
    else
        self:emit('error','please wait initializing', 'ntp')
    end
end

function NTPClient:run(interval)
    assert(self.interval==nil)
    assert(type(interval)=='number')
    self.interval = timer.setInterval(interval*1000, function()
        self:query()
    end)
end

function NTPClient:stop()
    assert(self.interval)
    timer.clearInterval(self.interval)
    self.interval = nil
end

function NTPClient:destroy()
    if self.socket then
        self.socket:close()
    end
end

return NTPClient
