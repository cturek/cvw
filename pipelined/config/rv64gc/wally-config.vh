//////////////////////////////////////////
// wally-config.vh
//
// Written: David_Harris@hmc.edu 4 January 2021
// Modified: 
//
// Purpose: Specify which features are configured
//          Macros to determine which modes are supported based on MISA
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

// include shared configuration
`include "wally-shared.vh"

`define FPGA 0
`define QEMU 0
`define DESIGN_COMPILER 0

// RV32 or RV64: XLEN = 32 or 64
`define XLEN 64

// IEEE 754 compliance
`define IEEE754 0

// MISA RISC-V configuration per specification
`define MISA (32'h00000104 | 1 << 5 | 1 << 3 | 1 << 18 | 1 << 20 | 1 << 12 | 1 << 0 )
`define ZICSR_SUPPORTED 1
`define ZIFENCEI_SUPPORTED 1
`define COUNTERS 32
`define ZICOUNTERS_SUPPORTED 1

/// Microarchitectural Features
`define UARCH_PIPELINED 1
`define UARCH_SUPERSCALR 0
`define UARCH_SINGLECYCLE 0
`define DMEM `MEM_CACHE
`define IMEM `MEM_CACHE
`define MEM_VIRTMEM 1
`define VECTORED_INTERRUPTS_SUPPORTED 1 

// TLB configuration.  Entries should be a power of 2
`define ITLB_ENTRIES 32
`define DTLB_ENTRIES 32

// Cache configuration.  Sizes should be a power of two
// typical configuration 4 ways, 4096 bytes per way, 256 bit or more lines
`define DCACHE_NUMWAYS 4
`define DCACHE_WAYSIZEINBYTES 4096
`define DCACHE_LINELENINBITS 256
`define DCACHE_REPLBITS 3
`define ICACHE_NUMWAYS 4
`define ICACHE_WAYSIZEINBYTES 4096
`define ICACHE_LINELENINBITS 256

// Integer Divider Configuration
// DIV_BITSPERCYCLE must be 1, 2, or 4
`define DIV_BITSPERCYCLE 4

// Legal number of PMP entries are 0, 16, or 64
`define PMP_ENTRIES 64

// Address space
`define RESET_VECTOR 64'h0000000080000000

// Bus Interface width
`define AHBW 64

// Peripheral Physiccal Addresses
// Peripheral memory space extends from BASE to BASE+RANGE
// Range should be a thermometer code with 0's in the upper bits and 1s in the lower bits

// *** each of these is `PA_BITS wide. is this paramaterizable INSIDE the config file?
`define BOOTROM_SUPPORTED 1'b1
`define BOOTROM_BASE   56'h00001000 // spec had been 0x1000 to 0x2FFF, but dh truncated to 0x1000 to 0x1FFF because upper half seems to be all zeros and this is easier for decoder
`define BOOTROM_RANGE  56'h00000FFF
`define RAM_SUPPORTED 1'b1
`define RAM_BASE       56'h80000000
`define RAM_RANGE      56'h7FFFFFFF
`define EXT_MEM_SUPPORTED 1'b0
`define EXT_MEM_BASE       56'h80000000
`define EXT_MEM_RANGE      56'h07FFFFFF
`define CLINT_SUPPORTED 1'b1
`define CLINT_BASE  56'h02000000
`define CLINT_RANGE 56'h0000FFFF
`define GPIO_SUPPORTED 1'b1
`define GPIO_BASE   56'h10060000
`define GPIO_RANGE  56'h000000FF
`define UART_SUPPORTED 1'b1
`define UART_BASE   56'h10000000
`define UART_RANGE  56'h00000007
`define PLIC_SUPPORTED 1'b1
`define PLIC_BASE   56'h0C000000
`define PLIC_RANGE  56'h03FFFFFF
`define SDC_SUPPORTED 1'b0
`define SDC_BASE   56'h00012100
`define SDC_RANGE  56'h0000001F

// Test modes

// Tie GPIO outputs back to inputs
`define GPIO_LOOPBACK_TEST 1

// Hardware configuration
`define UART_PRESCALE 1

// Interrupt configuration
`define PLIC_NUM_SRC 4
// comment out the following if >=32 sources
`define PLIC_NUM_SRC_LT_32
`define PLIC_GPIO_ID 3
`define PLIC_UART_ID 4

`define TWO_BIT_PRELOAD "../config/rv64ic/twoBitPredictor.txt"
`define BTB_PRELOAD "../config/rv64ic/BTBPredictor.txt"
`define BPRED_ENABLED 1
`define BPTYPE "BPGSHARE" // BPLOCALPAg or BPGLOBAL or BPTWOBIT or BPGSHARE
`define TESTSBP 0

