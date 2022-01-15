#include <SPI.h>

int pin_spi_cs_n = 8;

// choose which ROM to load
//#define ROM_SUPERMARIO
//#define ROM_DONKEYKONG
//#define ROM_NESTEST
#define ROM_INTEGRATIONTEST


#ifdef ROM_SUPERMARIO
#include "supermario/chr_rom_bank_0.bin.h"
#include "supermario/prg_rom_bank_0.6502.bin.h"
#include "supermario/prg_rom_bank_1.6502.bin.h"
#endif

#ifdef ROM_DONKEYKONG
#include "donkeykong/chr_rom_bank_0.bin.h"
#include "donkeykong/prg_rom_bank_0.6502.bin.h"
#endif

#ifdef ROM_NESTEST
#include "nestest/chr_rom_bank_0.bin.h"
#include "nestest/prg_rom_bank_0.6502.bin.h"
#endif

enum class Command : byte {
  NOP = 0,
  ECHO = 1,
  MEM_WRITE = 2,
  MEM_READ = 3,
  VALUE_WRITE = 4,
  VALUE_READ = 5
};

///////////////////////////////////////////////////////////////////////////
// Utilities

byte hi(uint16_t value) {
  return (value >> 8) & 0xff;
}

byte lo(uint16_t value) {
  return value & 0xff;
}

///////////////////////////////////////////////////////////////////////////
// SPI commands

void nop() {
  SPI.transfer(byte(Command::NOP));
}

byte echo(byte value) {
  SPI.transfer(byte(Command::ECHO));
  SPI.transfer(value);
  byte returnValue = SPI.transfer(0);
  
  return returnValue;
}

void memWrite(uint16_t dst, const byte* src, uint16_t numBytes) {
  SPI.transfer(byte(Command::MEM_WRITE));
  SPI.transfer(hi(dst));
  SPI.transfer(lo(dst));
  SPI.transfer(hi(numBytes));
  SPI.transfer(lo(numBytes));
  for (uint16_t i=0; i<numBytes; i++) {
    SPI.transfer(src[i]);
  }
}

void memRead(uint16_t src, byte* dst, uint16_t numBytes) {
  SPI.transfer(byte(Command::MEM_READ));
  SPI.transfer(hi(src));
  SPI.transfer(lo(src));
  SPI.transfer(hi(numBytes));
  SPI.transfer(lo(numBytes));
  for (uint16_t i=0; i<numBytes; i++) {
    dst[i] = SPI.transfer(0);
  }
}

void valueWrite(uint16_t id, uint16_t value) {
  SPI.transfer(byte(Command::VALUE_WRITE));
  SPI.transfer(hi(id));
  SPI.transfer(lo(id));
  SPI.transfer(hi(value));
  SPI.transfer(lo(value));
}

uint16_t valueRead(uint16_t id) {
  SPI.transfer(byte(Command::VALUE_READ));
  SPI.transfer(hi(id));
  SPI.transfer(lo(id));
  uint8_t valueHi = SPI.transfer(0);
  uint8_t valueLo = SPI.transfer(0);
  
  uint16_t value = (uint16_t(valueHi) << 8) | uint16_t(valueLo);
  
  return value;
}

void SetSpiChipSelectEnabled(bool isEnabled) {
  digitalWrite(pin_spi_cs_n, isEnabled ? LOW : HIGH);
}

///////////////////////////////////////////////////////////////////////////
// SPI startup

void syncSPI() {
  // repeatedly try to echo some values from SPI until successful
  // - if you see this failing, then probably need to reset the FPGA

  bool hasSynchronised = false;

  Serial.println("syncSPI - begin");

  while (!hasSynchronised) {
    SetSpiChipSelectEnabled(true);
    
    nop();
    
    byte values[3] = { 43, 99, 245 };

    bool hasFailed = false;

    for (int i=0; i<3; i++) {
      byte value = values[i];
      byte returned = echo(value);
      
      if (value != returned) {
        Serial.print("syncSPI failed: echo ");
        Serial.print(value);
        Serial.print(" != ");
        Serial.println(returned);
      
        hasFailed = true;
        break;
      }
    }

    if (hasFailed) {
      delay(1000);
    } else {
      hasSynchronised = true;
    }

    SetSpiChipSelectEnabled(false);
  }

  
  Serial.println("syncSPI - complete");
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Test Design

void testMemory() {
  // echo
  const byte kEchoSequence[3] = { 43, 99, 245 };

  for (int i=0; i<3; i++) {
    const byte value = kEchoSequence[i];
    byte returned = echo(value);
    Serial.print("echo ");
    Serial.print(value);
    Serial.print(" => ");
    Serial.println(returned);
  }

  // mem write
  const uint16_t kDataSize = 3;
  const byte data[kDataSize] = { 0xAA, 0xBB, 0xCC };
  memWrite(0xABCD, data, kDataSize);

  // mem read 
  byte readData[kDataSize];
  memRead(0xABCD, readData, kDataSize);

  Serial.print("Memory Read: ");
  for (uint16_t i=0; i < kDataSize; i++) {
    Serial.print(readData[i], HEX);
    Serial.print(", ");
  }
  Serial.println("");
}

enum ValueID : uint16_t {
  VALUEID_NES_RESET_N = 1,
  VALUEID_DEBUGGER_MEMORY_POOL = 2
};

enum MemoryPool : uint16_t {
  MEMORY_POOL_PRG = 0,
  MEMORY_POOL_RAM = 1,
  MEMORY_POOL_PATTERNTABLE = 2,
  MEMORY_POOL_NAMETABLE = 3,

  NUM_MEMORY_POOLS = 4
};

// fill 64kByte memory pool with value
void fillMemory(byte value) {
  const int kBufferSize = 128;
  byte buffer[kBufferSize];
  memset(buffer, value, kBufferSize);
  for (int i=0; i<0x10000; i+= kBufferSize) {
    memWrite(i, buffer, kBufferSize);
  }
}

void setResetN(uint16_t resetn) {
  valueWrite(VALUEID_NES_RESET_N, resetn);
}

void testNesDebugger() {
  Serial.println("Testing NES Debugger");
  char msg[64];
  
  for (uint16_t memoryPool=0; memoryPool < NUM_MEMORY_POOLS; memoryPool++) {  
    sprintf(msg, "preparing memorypool [%d]", int(memoryPool));
    Serial.println(msg);
    
    valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, memoryPool);

    testMemory();

    fillMemory(memoryPool);
  }
 
  for (uint16_t memoryPool=0; memoryPool < NUM_MEMORY_POOLS; memoryPool++) {
    sprintf(msg, "verifying memorypool [%d]", int(memoryPool));
    Serial.println(msg);
    
    valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, memoryPool);

    byte data;
    memRead(0, &data, 1);
    if (data != memoryPool){
      sprintf(msg, "failed to verify memorypool [%d]", int(memoryPool));
    }
  }

}

///////////////////////////////////////////////////////////////////////////
// testing

void setupTest() {
  Serial.println("**** setupTest");
  SetSpiChipSelectEnabled(true);

  // put NES into reset mode
  setResetN(0);

  SetSpiChipSelectEnabled(false);
}

void loopTest() {
  Serial.println("**** loopTest");
  SetSpiChipSelectEnabled(true);

  testNesDebugger();

  SetSpiChipSelectEnabled(false);
}

///////////////////////////////////////////////////////////////////////////
// running NES ROMs

void setupROM() {
  Serial.println("**** setupROM - start");
  SetSpiChipSelectEnabled(true);

  // put NES in reset mode
  setResetN(0);

  //Serial.println(" 5 second delay - does VGA output stop?");
  //delay(5000);

#ifdef ROM_NESTEST
  Serial.println("NES TEST");
  // chr @ 0x0000
  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PATTERNTABLE);
  memWrite(0x0000, chr_rom_bank_0_bin, 0x3FFF);

  // prg @ 0xc000
  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PRG);
  memWrite(0xc000, prg_rom_bank_0_6502_bin, 0x3FFF);

  // TODO:
  // if only using CPU tests then fix up the RESET vector address to 
  //sram.write(0xfffc, 0x00);       // low byte
  //sram.write(0xfffd, 0xc0);       // high byte
#endif

#ifdef ROM_DONKEYKONG
  Serial.println("Donkey Kong");
  // chr @ 0x0000
  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PATTERNTABLE);
  memWrite(0x0000, chr_rom_bank_0_bin, 0x3FFF);

  // prg @ 0xc000
  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PRG);
  memWrite(0xc000, prg_rom_bank_0_6502_bin, 0x3FFF);
#endif

#ifdef ROM_SUPERMARIO
  Serial.println("SuperMario");
  // chr @ 0x0000
  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PATTERNTABLE);
  memWrite(0x0000, chr_rom_bank_0_bin, 0x3FFF);

  // prg @ 0x8000, 0xc000
  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PRG);
  memWrite(0x8000, prg_rom_bank_0_6502_bin, 0x3FFF);
  memWrite(0xc000, prg_rom_bank_1_6502_bin, 0x3FFF);
#endif

#ifdef ROM_INTEGRATIONTEST
  Serial.println("Integration Test");

  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_RAM);
  fillMemory(0);

  valueWrite(VALUEID_DEBUGGER_MEMORY_POOL, MEMORY_POOL_PRG);
  fillMemory(0);
  
  // prg @ 0x8000
  byte prg[] = {
      0xa9, 0xff,           // lda #$ff
      0x8d, 0x02, 0x20,     // sta #$2002

      0xa9, 0x55,           // lda #$55,
      0x8d, 0x00, 0x20,     // sta #$2000

      0x4c, 0x0a, 0x80      // jmp $800a (this opcode)
  };

  // reset vector @ 0xfffc -> pointing to 0x8000
  byte resetVector[] = {
    0x00, 0x80
  };

  memWrite(0x8000, prg, 13);
  memWrite(0xfffc, resetVector, 2);
  
#endif

  // start NES running
  setResetN(1);

#ifdef ROM_INTEGRATIONTEST
  // test contents of memory

  byte a;
  memRead(0x2002, &a, 1);

  Serial.print("0x2002 - expected [0xFF] found [");
  Serial.print(a, HEX);
  Serial.println("]");
  
  byte b;
  memRead(0x2000, &b, 1);
   
  Serial.print("0x2000 - expected [0x55] found [");
  Serial.print(b, HEX);
  Serial.println("]");
#endif

  Serial.println("**** setupROM - complete");
}

///////////////////////////////////////////////////////////////////////////
// Arduino lifecycle

void setup() {
  Serial.begin(9600);
  Serial.println("NES Debugger");
  
  pinMode(pin_spi_cs_n, OUTPUT);
  SetSpiChipSelectEnabled(false);

  SPI.begin();
  SPI.beginTransaction(SPISettings(500000, MSBFIRST, SPI_MODE1));

  syncSPI();
  
  //setupTest();

  setupROM();

}

void loop() {
  //loopTest();
}
