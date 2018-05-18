//Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2017.1 (lin64) Build 1846317 Fri Apr 14 18:54:47 MDT 2017
//Date        : Tue Jun 27 19:01:47 2017
//Host        : xray running 64-bit Ubuntu 16.04.2 LTS
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

`default_nettype none

module bd_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    // user IO pins:
    clk100_p, clk100_n,
    mcuclk_copy_p, mcuclk_copy_n,
    // clk100_sel,
    a7_cfg_sclk, a7_cfg_d_in, a7_cfg_program_b,
    a7_cfg_done, a7_cfg_init_b,
    clkcln_sclk, clkcln_sdat, clkcln_sle,
    clkdiv_sclk, clkdiv_sdat, clkdiv_sle,
    drs_denable,
    // a7_softreset,
    uztoa7spare,
    a7touzspare,
    sr_oe_n, sr_ds, sr_stcp, sr_stcp0, sr_shcp,
    sr_q55s,  // read back final shift-out bit
    idrom_d,
    ro_sdatp, ro_sdatn,
    ro_holdp, ro_holdn,
    // bus_wdatp, bus_wdatn,
    // bus_rdatp, bus_rdatn,
    sdac_din, sdac_sclk,
    sdac_syncn,
    iv_scl0, // iv_scl1,  // ++ added 2017-01-20
    iv_sda0, // iv_sda1,
    pgood6,
    // clkcln_lckdtct,
    clkdiv_lckdtct,
    misc_tp,
    tpspare_1, tpspare_2, tpspare_3,
    tpspare_4, tpspare_5, tpspare_6, // --
    uzled,
    iocc_led
);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  // user IO pins:
  input         clk100_p, clk100_n;
  input         mcuclk_copy_p, mcuclk_copy_n;
  // output        clk100_sel;
  output        a7_cfg_sclk, a7_cfg_d_in, a7_cfg_program_b;
  input         a7_cfg_done, a7_cfg_init_b;
  output        clkcln_sclk, clkcln_sdat, clkcln_sle;
  output        clkdiv_sclk, clkdiv_sdat, clkdiv_sle;
  output        drs_denable;
  // output        a7_softreset;
  output [15:0] uztoa7spare;
  input  [15:0] a7touzspare;
  output        sr_oe_n, sr_ds, sr_stcp, sr_stcp0, sr_shcp;
  input         sr_q55s;  // read back final shift-out bit
  inout         idrom_d;
  input   [3:0] ro_sdatp, ro_sdatn;
  output        ro_holdp, ro_holdn;
  // output        bus_wdatp, bus_wdatn;
  // input         bus_rdatp, bus_rdatn;
  output        sdac_din, sdac_sclk;
  output  [1:0] sdac_syncn;
  output        iv_scl0; // , iv_scl1;  // ++ added 2017-01-20
  inout         iv_sda0; // , iv_sda1;
  input         pgood6;
  // input         clkcln_lckdtct;
  input         clkdiv_lckdtct;
  output        misc_tp;
  output        tpspare_1, tpspare_2, tpspare_3;
  output        tpspare_4, tpspare_5, tpspare_6; // --
  output  [3:0] uzled;
  output  [7:0] iocc_led;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FCLK_CLK0;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [31:0]R3;
  wire [31:0]R4;
  wire [31:0]R5;
  wire [31:0]R6;
  wire [31:0]R7;
  wire [31:0]reg0;
  wire [31:0]reg1;
  wire [31:0]reg2;
  // user IO pins:
  wire        clk100_p, clk100_n;
  wire        mcuclk_copy_p, mcuclk_copy_n;
  wire        clk100_sel;
  wire        a7_cfg_sclk, a7_cfg_d_in, a7_cfg_program_b;
  wire        a7_cfg_done, a7_cfg_init_b;
  wire        clkcln_sclk, clkcln_sdat, clkcln_sle;
  wire        clkdiv_sclk, clkdiv_sdat, clkdiv_sle;
  wire        drs_denable;
  wire        a7_softreset;
  wire [15:0] uztoa7spare;
  wire [15:0] a7touzspare;
  wire        sr_oe_n, sr_ds, sr_stcp, sr_stcp0, sr_shcp;
  wire        sr_q55s;  // read back final shift-out bit
  wire        idrom_d;
  wire  [3:0] ro_sdatp, ro_sdatn;
  wire        ro_holdp, ro_holdn;
  wire        bus_wdatp, bus_wdatn;
  wire        bus_rdatp, bus_rdatn;
  wire        sdac_din, sdac_sclk;
  wire  [1:0] sdac_syncn;
  wire        iv_scl0, iv_scl1;  // ++ added 2017-01-20
  wire        iv_sda0, iv_sda1;
  wire        pgood6;
  wire        clkcln_lckdtct;
  wire        clkdiv_lckdtct;
  wire        misc_tp;
  wire        tpspare_1, tpspare_2, tpspare_3;
  wire        tpspare_4, tpspare_5, tpspare_6; // --
  wire  [3:0] uzled;
  wire  [7:0] iocc_led;

  bd bd_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
	.FCLK_CLK0(FCLK_CLK0),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
	.R3(R3),
	.R4(R4),
	.R5(R5),
	.R6(R6),
	.R7(R7),
	.reg0(reg0),
	.reg1(reg1),
	.reg2(reg2));

 mrb_uzed mu
    (.clk(FCLK_CLK0), 
     .r0(reg0), .r1(reg1), .r2(reg2), 
     .r3(R3), .r4(R4), .r5(R5), .r6(R6), .r7(R7),
     // user I/O pins:
     .clk100_p(clk100_p), .clk100_n(clk100_n),
     .mcuclk_copy_p(mcuclk_copy_p), .mcuclk_copy_n(mcuclk_copy_n),
     .a7_cfg_sclk(a7_cfg_sclk), .a7_cfg_d_in(a7_cfg_d_in),
     .a7_cfg_program_b(a7_cfg_program_b),
     .a7_cfg_done(a7_cfg_done), .a7_cfg_init_b(a7_cfg_init_b),
     .clkcln_sclk(clkcln_sclk), .clkcln_sdat(clkcln_sdat), 
     .clkcln_sle(clkcln_sle),
     .clkdiv_sclk(clkdiv_sclk), .clkdiv_sdat(clkdiv_sdat),
     .clkdiv_sle(clkdiv_sle),
     .drs_denable(drs_denable),
     .uztoa7spare(uztoa7spare), .a7touzspare(a7touzspare),
     .sr_oe_n(sr_oe_n), .sr_ds(sr_ds), .sr_stcp(sr_stcp),
     .sr_stcp0(sr_stcp0), .sr_shcp(sr_shcp), .sr_q55s(sr_q55s),
     .idrom_d(idrom_d),
     .ro_sdatp(ro_sdatp), .ro_sdatn(ro_sdatn),
     .ro_holdp(ro_holdp), .ro_holdn(ro_holdn),
     .sdac_din(sdac_din), .sdac_sclk(sdac_sclk), .sdac_syncn(sdac_syncn),
     .iv_scl0(iv_scl0), 
     .iv_sda0(iv_sda0), 
     .pgood6(pgood6),
     .clkdiv_lckdtct(clkdiv_lckdtct),
     .misc_tp(misc_tp),
     .tpspare_1(tpspare_1), .tpspare_2(tpspare_2), .tpspare_3(tpspare_3),
     .tpspare_4(tpspare_4), .tpspare_5(tpspare_5), .tpspare_6(tpspare_6),
     .uzled(uzled),
     .iocc_led(iocc_led)
);

endmodule

`default_nettype wire

