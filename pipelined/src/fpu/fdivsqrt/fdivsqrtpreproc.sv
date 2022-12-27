///////////////////////////////////////////
// fdivsqrtpreproc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module fdivsqrtpreproc (
  input  logic clk,
  input  logic IFDivStartE, 
  input  logic [`NF:0] Xm, Ym,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic [`FMTBITS-1:0] Fmt,
  input  logic Sqrt,
  input  logic XZeroE,
  input  logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	input  logic [2:0] 	Funct3E,
	input  logic MDUE, W64E,
  output logic [`DIVBLEN:0] nE, nM, mM,
  output logic NegQuotM, ALTBM, MDUM,
  output logic AsM, AZeroM, BZeroM, AZeroE, BZeroE,
  output logic [`NE+1:0] QeM,
  output logic [`DIVb+3:0] X,
  output logic [`DIVb-1:0] DPreproc,
  output logic [`XLEN-1:0] ForwardedSrcAM
);

  logic  [`DIVb-1:0] XPreproc;
  logic  [`DIVb:0] SqrtX;
  logic  [`DIVb+3:0] DivX;
  logic  [`NE+1:0] QeE;
  // Intdiv signals
  logic  [`DIVb-1:0] IFNormLenX, IFNormLenD;
  logic  [`XLEN-1:0] PosA, PosB;
  logic  AsE, BsE, ALTBE, NegQuotE;
  logic  [`XLEN-1:0]  A64, B64;
  logic  [`DIVBLEN:0] mE;
  logic  [`DIVBLEN:0] ZeroDiff, IntBits, RightShiftX;
  logic  [`DIVBLEN:0] pPlusr, pPrCeil, p, ell;
  logic  [`LOGRK:0] pPrTrunc;
  logic  [`DIVb+3:0]  PreShiftX;
  logic  NumZeroE;

  // ***can probably merge X LZC with conversion
  // cout the number of leading zeros

  assign AsE = ForwardedSrcAE[`XLEN-1] & ~Funct3E[0];
  assign BsE = ForwardedSrcBE[`XLEN-1] & ~Funct3E[0];
  assign A64 = W64E ? {{(`XLEN-32){AsE}}, ForwardedSrcAE[31:0]} : ForwardedSrcAE;
  assign B64 = W64E ? {{(`XLEN-32){BsE}}, ForwardedSrcBE[31:0]} : ForwardedSrcBE;

  assign NegQuotE = (AsE ^ BsE) & MDUE;
  
  assign PosA = AsE ? -A64 : A64;
  assign PosB = BsE ? -B64 : B64;
  assign AZeroE = ~(|ForwardedSrcAE);
  assign BZeroE = ~(|ForwardedSrcBE);

  assign IFNormLenX = MDUE ? {PosA, {(`DIVb-`XLEN){1'b0}}} : {Xm, {(`DIVb-`NF-1){1'b0}}};
  assign IFNormLenD = MDUE ? {PosB, {(`DIVb-`XLEN){1'b0}}} : {Ym, {(`DIVb-`NF-1){1'b0}}};
  lzc #(`DIVb) lzcX (IFNormLenX, ell);
  lzc #(`DIVb) lzcY (IFNormLenD, mE);

  assign XPreproc = IFNormLenX << (ell + {{`DIVBLEN{1'b0}}, 1'b1}); // had issue with (`DIVBLEN+1)'(~MDUE) so using this instead
  assign DPreproc = IFNormLenD << (mE + {{`DIVBLEN{1'b0}}, 1'b1}); // replaced ~MDUE with 1 bc we always want that extra left shift

  assign ZeroDiff = mE - ell;
  assign ALTBE = ZeroDiff[`DIVBLEN]; // A less than B
  assign p = ALTBE ? '0 : ZeroDiff;

/* verilator lint_off WIDTH */
  assign pPlusr = (`DIVBLEN)'(`LOGR) + p;
  assign pPrTrunc = pPlusr % `RK;
//assign pPrTrunc = (`LOGRK == 0) ? 0 : pPlusr[`LOGRK-1:0];
  assign pPrCeil = (pPlusr >> `LOGRK) + {{`DIVBLEN{1'b0}}, |(pPrTrunc)};
  assign nE = (pPrCeil * (`DIVBLEN+1)'(`DIVCOPIES)) - {{(`DIVBLEN){1'b0}}, 1'b1};
  assign IntBits = (`DIVBLEN)'(`LOGR) + p - {{(`DIVBLEN){1'b0}}, 1'b1};
  assign RightShiftX = ((`DIVBLEN)'(`RK) - 1) - (IntBits % `RK);
//assign RightShiftX = (`LOGRK == 0) ? 0 : ((`DIVBLEN)'(`RK) - 1) - {{(`DIVBLEN - `RK){1'b0}}, IntBits[`LOGRK-1:0]};
/* verilator lint_on WIDTH */

  assign NumZeroE = MDUE ? AZeroE : XZeroE;

  assign SqrtX = (Xe[0]^ell[0]) ? {1'b0, ~NumZeroE, XPreproc[`DIVb-1:1]} : {~NumZeroE, XPreproc}; // Bottom bit of XPreproc is always zero because DIVb is larger than XLEN and NF
  assign DivX = {3'b000, ~NumZeroE, XPreproc};

  // *** explain why X is shifted between radices (initial assignment of WS=RX)
  if (`RADIX == 2)  assign PreShiftX = Sqrt ? {3'b111, SqrtX} : DivX;
  else              assign PreShiftX = Sqrt ? {2'b11, SqrtX, 1'b0} : DivX;
  assign X = MDUE ? DivX >> RightShiftX : PreShiftX;

  fdivsqrtexpcalc expcalc(.Fmt, .Xe, .Ye, .Sqrt, .XZeroE, .ell, .m(mE), .Qe(QeE));

  //           radix 2     radix 4
  // 1 copies  DIVLEN+2    DIVLEN+2/2
  // 2 copies  DIVLEN+2/2  DIVLEN+2/2*2
  // 4 copies  DIVLEN+2/4  DIVLEN+2/2*4
  // 8 copies  DIVLEN+2/8  DIVLEN+2/2*8

  // DIVRESLEN = DIVLEN or DIVLEN+2
  // r = 1 or 2
  // DIVRESLEN/(r*`DIVCOPIES)

  flopen #(`NE+2)    expreg(clk, IFDivStartE, QeE, QeM);
  flopen #(1)    negquotreg(clk, IFDivStartE, NegQuotE, NegQuotM);
  flopen #(1)       altbreg(clk, IFDivStartE, ALTBE, ALTBM);
  flopen #(1)      azeroreg(clk, IFDivStartE, AZeroE, AZeroM);
  flopen #(1)      bzeroreg(clk, IFDivStartE, BZeroE, BZeroM);
  flopen #(1)      asignreg(clk, IFDivStartE, AsE, AsM);
  flopen #(1)        mdureg(clk, IFDivStartE, MDUE, MDUM);
  flopen #(`DIVBLEN+1) nreg(clk, IFDivStartE, nE, nM);
  flopen #(`DIVBLEN+1) mreg(clk, IFDivStartE, mE, mM);
  flopen #(`XLEN)   srcareg(clk, IFDivStartE, ForwardedSrcAE, ForwardedSrcAM);


endmodule

