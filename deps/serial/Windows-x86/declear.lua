--[[
/* GUIDs */

DEFINE_GUID(GUID_DEVINTERFACE_COMPORT,
  0x86e0d1e0, 0x8089, 0x11d0, 0x9c, 0xe4, 0x08, 0x00, 0x3e, 0x30, 0x1f, 0x73);

#define GUID_CLASS_COMPORT GUID_DEVINTERFACE_COMPORT

DEFINE_GUID(GUID_DEVINTERFACE_SERENUM_BUS_ENUMERATOR,
  0x4D36E978, 0xE325, 0x11CE, 0xBF, 0xC1, 0x08, 0x00, 0x2B, 0xE1, 0x03, 0x18);

#define GUID_SERENUM_BUS_ENUMERATOR GUID_DEVINTERFACE_SERENUM_BUS_ENUMERATOR
--]]
local ffi = require'ffi'

ffi.cdef([[
  typedef unsigned long ULONG;
  typedef unsigned char UCHAR;
  typedef int BOOLEAN;
  typedef long LONG;
  typedef short SHORT;
  typedef unsigned short USHORT;
  typedef unsigned short WCHAR;
  typedef void* PVOID;
  typedef __int64 LONGLONG, *PLONGLONG; 
  
  typedef struct _LARGE_INTEGER {
    LONGLONG QuadPart;
  } LARGE_INTEGER, *PLARGE_INTEGER;
  typedef LARGE_INTEGER PHYSICAL_ADDRESS;
  
typedef struct _SERIAL_BAUD_RATE {
  ULONG  BaudRate;
} SERIAL_BAUD_RATE, *PSERIAL_BAUD_RATE;

typedef struct _SERIAL_CHARS {
  UCHAR  EofChar;
  UCHAR  ErrorChar;
  UCHAR  BreakChar;
  UCHAR  EventChar;
  UCHAR  XonChar;
  UCHAR  XoffChar;
} SERIAL_CHARS, *PSERIAL_CHARS;

typedef struct _SERIAL_STATUS {
  ULONG  Errors;
  ULONG  HoldReasons;
  ULONG  AmountInInQueue;
  ULONG  AmountInOutQueue;
  BOOLEAN  EofReceived;
  BOOLEAN  WaitForImmediate;
} SERIAL_STATUS, *PSERIAL_STATUS;

typedef struct _SERIAL_HANDFLOW {
	ULONG  ControlHandShake;
	ULONG  FlowReplace;
	LONG  XonLimit;
	LONG  XoffLimit;
} SERIAL_HANDFLOW, *PSERIAL_HANDFLOW;

typedef struct _SERIAL_LINE_CONTROL {
  UCHAR  StopBits;
  UCHAR  Parity;
  UCHAR  WordLength;
} SERIAL_LINE_CONTROL, *PSERIAL_LINE_CONTROL;

typedef struct _SERIAL_COMMPROP {
  USHORT  PacketLength;
  USHORT  PacketVersion;
  ULONG  ServiceMask;
  ULONG  Reserved1;
  ULONG  MaxTxQueue;
  ULONG  MaxRxQueue;
  ULONG  MaxBaud;
  ULONG  ProvSubType;
  ULONG  ProvCapabilities;
  ULONG  SettableParams;
  ULONG  SettableBaud;
  USHORT  SettableData;
  USHORT  SettableStopParity;
  ULONG  CurrentTxQueue;
  ULONG  CurrentRxQueue;
  ULONG  ProvSpec1;
  ULONG  ProvSpec2;
  WCHAR  ProvChar[1];
} SERIAL_COMMPROP, *PSERIAL_COMMPROP;

typedef struct _SERIALPERF_STATS {
  ULONG  ReceivedCount;
  ULONG  TransmittedCount;
  ULONG  FrameErrorCount;
  ULONG  SerialOverrunErrorCount;
  ULONG  BufferOverrunErrorCount;
  ULONG  ParityErrorCount;
} SERIALPERF_STATS, *PSERIALPERF_STATS;

typedef struct _SERIAL_TIMEOUTS {
  ULONG  ReadIntervalTimeout;
  ULONG  ReadTotalTimeoutMultiplier;
  ULONG  ReadTotalTimeoutConstant;
  ULONG  WriteTotalTimeoutMultiplier;
  ULONG  WriteTotalTimeoutConstant;
} SERIAL_TIMEOUTS, *PSERIAL_TIMEOUTS;

typedef struct _SERIAL_QUEUE_SIZE {
  ULONG  InSize;
  ULONG  OutSize;
} SERIAL_QUEUE_SIZE, *PSERIAL_QUEUE_SIZE;

typedef struct _SERIAL_XOFF_COUNTER {
	ULONG  Timeout;
	LONG  Counter;
	UCHAR  XoffChar;
} SERIAL_XOFF_COUNTER, *PSERIAL_XOFF_COUNTER;

typedef struct _SERIAL_BASIC_SETTINGS {
	SERIAL_TIMEOUTS  Timeouts;
	SERIAL_HANDFLOW  HandFlow;
	ULONG  RxFifo;
	ULONG  TxFifo;
} SERIAL_BASIC_SETTINGS, *PSERIAL_BASIC_SETTINGS;

typedef struct _SERENUM_PORT_DESC {
	ULONG  Size;
	PVOID  PortHandle;
	PHYSICAL_ADDRESS  PortAddress;
	USHORT  Reserved[1];
} SERENUM_PORT_DESC, *PSERENUM_PORT_DESC;


typedef enum _SERENUM_PORTION {
  SerenumFirstHalf,
  SerenumSecondHalf,
  SerenumWhole
} SERENUM_PORTION;

typedef struct _SERIALCONFIG {
  ULONG  Size;
  USHORT  Version;
  ULONG  SubType;
  ULONG  ProvOffset;
  ULONG  ProviderSize;
  WCHAR  ProviderData[1];
} SERIALCONFIG,*PSERIALCONFIG;
typedef unsigned long DWORD;
typedef struct _COMMTIMEOUTS {
  DWORD ReadIntervalTimeout;
  DWORD ReadTotalTimeoutMultiplier;
  DWORD ReadTotalTimeoutConstant;
  DWORD WriteTotalTimeoutMultiplier;
  DWORD WriteTotalTimeoutConstant;
} COMMTIMEOUTS, *LPCOMMTIMEOUTS;
]])
