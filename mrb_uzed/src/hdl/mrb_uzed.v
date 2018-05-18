/*
 * mrb_uzed.v
 * Implement "Programmable Logic" (PL) side of MicroZed for MRB2 board
 * begun 2015-07-22 by wja, starting from MCU prototype's myverilog.v
 */

`timescale 1ns / 1ps
`default_nettype none

module mrb_uzed
  (
   // MicroZed internal clock
   input  wire        clk,
   // for communication with PS (CPU) side
   input  wire [31:0] r0, r1, r2,
   output wire [31:0] r3, r4, r5, r6, r7,
   // ## I/O pins start here: ##
   // Net "uz_clk100_[pn]" from "clk100fo" sy89828
   input  wire        clk100_p, clk100_n,
   // Net "mcuclk_copy_[pn]" from "clkcln" lmk03000, to allow uzed to
   // see presence of incoming MCU clock and that lmk03000 works.
   input  wire        mcuclk_copy_p, mcuclk_copy_n,
   // Net "clk100_sel" to "clk100fo" sy89828, to select between MCU
   // clock and MRB's on-board 100 MHz oscillator.
   output wire        clk100_sel,
   // Configuration lines for Artix7 FPGA
   output wire        a7_cfg_sclk, a7_cfg_d_in, a7_cfg_program_b,
   input  wire        a7_cfg_done, a7_cfg_init_b,
   // To configure "clkcln" lmk03000
   output wire        clkcln_sclk, clkcln_sdat, clkcln_sle,
   // To configure "clkdiv" lmk03000
   output wire        clkdiv_sclk, clkdiv_sdat, clkdiv_sle,
   // Output to drive DENABLE pins on all DRS4 chips
   output wire        drs_denable,
   // Generic lines to/from Artix7 FPGA
   output wire        a7_softreset,
   output wire [15:0] uztoa7spare,
   input  wire [15:0] a7touzspare,
   // To 74hc595 shift registers that drive infrequently-updated outputs
   output wire        sr_oe_n, sr_ds, sr_stcp, sr_stcp0, sr_shcp,
   input  wire        sr_q55s,  // read back final shift-out bit
   // To "idrom" ds2411, for unique serial number
   inout  wire        idrom_d,
   // High-speed waveform readout from Artix7 (4 x 400 Mbps?)
   input  wire  [3:0] ro_sdatp, ro_sdatn,
   output wire        ro_holdp, ro_holdn,
   // Register-file I/O to/from Artix7, for slow control
   output wire        bus_wdatp, bus_wdatn,
   input  wire        bus_rdatp, bus_rdatn,
   // Serial DACs to set various offset and common-mode voltages
   output wire        sdac_din, sdac_sclk,
   output wire  [1:0] sdac_syncn,
   // ++ added 2017-01-20
   output wire        iv_scl0, iv_scl1,
   inout  wire        iv_sda0, iv_sda1,
   input  wire        pgood6,
   input  wire        clkcln_lckdtct,
   input  wire        clkdiv_lckdtct,
   output wire        misc_tp,
   output wire        tpspare_1, tpspare_2, tpspare_3,
   output wire        tpspare_4, tpspare_5, tpspare_6,
   // --
   // A few LEDs wired directly to MicroZed (Bank 13)
   output wire  [3:0] uzled
   );
    // This 100 MHz clock drives nearly all logic on the board; it
    // originates from either the MCU clock or an on-board 100 MHz
    // oscillator, depending on the value of "clk100_sel"
    wire clk100;
    zilvds i_clk100(clk100, clk100_p, clk100_n);
    // This is a copy of the MCU clock, which may be useful for
    // determining whether the MCU clock is present and working
    wire mcuclk_copy;
    zilvds i_mcuclk_copy(mcuclk_copy, mcuclk_copy_p, mcuclk_copy_n);
    // High-speed waveform readout from Artix7
    wire [3:0] ro_sdat;
    zilvds i_ro_sdat0(ro_sdat[0], ro_sdatp[0], ro_sdatn[0]);
    zilvds i_ro_sdat1(ro_sdat[1], ro_sdatp[1], ro_sdatn[1]);
    zilvds i_ro_sdat2(ro_sdat[2], ro_sdatp[2], ro_sdatn[2]);
    zilvds i_ro_sdat3(ro_sdat[3], ro_sdatp[3], ro_sdatn[3]);
    wire ro_hold;
    zolvds o_ro_hold(ro_hold, ro_holdp, ro_holdn);
    
    // =====
    wire clkfb, clkfbg, clk100_ps1, clk100_ps1b, clk100_ps2, clk100_ps3;
    MMCME2_BASE
      #( .CLKFBOUT_MULT_F(8), .CLKIN1_PERIOD(10.0),
	 .CLKOUT1_DIVIDE(8), .CLKOUT2_DIVIDE(8), .CLKOUT3_DIVIDE(8),
	 .CLKOUT1_PHASE(0), .CLKOUT2_PHASE(45), .CLKOUT3_PHASE(90))
    mmcm ( .CLKIN1(clk100), .RST(1'b0), .PWRDWN(1'b0),
	   .CLKOUT1(clk100_ps1), .CLKOUT2(clk100_ps2), .CLKOUT3(clk100_ps3),
	   .CLKOUT4(), .CLKOUT5(), .CLKOUT6(), .CLKFBOUTB(), .LOCKED(),
	   .CLKOUT0B(), .CLKOUT1B(clk100_ps1b), .CLKOUT2B(), .CLKOUT3B(),
	   .CLKFBOUT(clkfb), .CLKFBIN(clkfbg));
    BUFG bufg_fb (.I(clkfb), .O(clkfbg));

    // Place holders to keep I/O from being optimized away
    //assign a7_softreset = 1'b0;
    //assign uzled = 4'b0;
    wire [7:0] uztoa7, a7touz;
    genvar ii;
    generate
	for (ii=0; ii<8; ii=ii+1) begin: a7spare
	    zilvds ilvds (a7touz[ii], a7touzspare[2*ii], a7touzspare[2*ii+1]);
	    zolvds olvds (uztoa7[ii], uztoa7spare[2*ii], uztoa7spare[2*ii+1]);
	end
    endgenerate

    // Instantiate "bus" I/O
    wire [15:0] baddr, bwrdata;
    wire [15:0] brddata;
    wire 	bwr, bstrobe;
    wire [33:0] ibus = {clk, bwr, baddr, bwrdata};
    wire [15:0] obus;
    assign brddata = obus;
    bus_zynq_gpio bus_zynq_gpio
      (.clk(clk), .clk100(clk100), .r0(r0), .r1(r1), .r2(r2),
       .r3(r3), .r4(r4), .r5(), .r6(r6), .r7(r7),
       .baddr(baddr), .bwr(bwr), .bstrobe(bstrobe),
       .bwrdata(bwrdata), .brddata(brddata));
    assign r5 = {brddata,baddr};
    zror #(16'h0000) r0000(ibus, obus, 16'h1129);
    zror #(16'h0001) r0001(ibus, obus, 16'hbeef);
    zror #(16'h0002) r0002(ibus, obus, 16'hdead);
    wire [15:0] q0003;
    assign clk100_sel = q0003[0];
    assign a7_softreset = q0003[1];
    zreg #(16'h0003) r0003(ibus, obus, q0003);
    wire [15:0] q0004;
    assign a7_cfg_program_b = ~q0004[8];
    assign drs_denable = q0004[12];  // flip sign 2017-05-04
    zreg #(16'h0004) r0004(ibus, obus, q0004);
    wire [15:0] q0005;
    assign q0005[0] = a7_cfg_done;
    assign q0005[3:1] = 0;
    assign q0005[4] = ~a7_cfg_init_b;
    assign q0005[15:5] = 0;
    zror #(16'h0005) r0005(ibus, obus, q0005);
    // For configuring Artix7 FPGA via "bus" writes
    reg [15:0] a7cfg_word = 0;
    reg [6:0] a7cfg_state = 0;
    reg a7cfg_sclk = 0, a7cfg_sdat = 0;
    assign a7_cfg_d_in = a7cfg_sdat;
    assign a7_cfg_sclk = a7cfg_sclk;
    always @ (posedge clk100) begin
	if (bstrobe && bwr && baddr==16'h0006) begin
	    a7cfg_state <= 2;
	    a7cfg_word <= bwrdata;
	end else if (a7cfg_state) begin
	    a7cfg_state <= a7cfg_state + 1;
	    if (a7cfg_state & 1) a7cfg_word <= {a7cfg_word[14:0],1'b0};
	    a7cfg_sclk <= ((a7cfg_state & 1) && (a7cfg_state < 34));
	    a7cfg_sdat <= a7cfg_word[15];
	end
    end
    // Divide down 100MHz 'clk' to count milliseconds and seconds
    reg [16:0] countto1ms = 0;  // wraps around once per millisecond
    reg [9:0]  countto1s  = 0;  // wraps around once per second
    reg        earlytick_1kHz = 0, tick_1kHz = 0, tick_1Hz = 0;
    reg [15:0] uptime = 0;      // count seconds since power-up
    always @ (posedge clk100) begin
	// 'earlytick' exists so that tick_1Hz and tick_1kHz coincide
	countto1ms <= (countto1ms==99999 ? 0 : countto1ms+1);
	earlytick_1kHz <= (countto1ms==99999);
	tick_1kHz <= earlytick_1kHz;
	if (earlytick_1kHz) countto1s <= (countto1s==999 ? 0 : countto1s+1);
	tick_1Hz <= earlytick_1kHz && countto1s==999;
	if (tick_1Hz) uptime <= uptime+1;
    end


    // Divide down clk100 to tick once per 25 MHz period
    reg [1:0] countto40ns = 0;
    reg       tick_25MHz = 0;
    reg       bitclk_25MHz = 0;
    always @ (posedge clk100) begin
	// phase tick_25MHz to coincide with tick_1kHz
	countto40ns <= earlytick_1kHz ? 0 : countto40ns+1;
	tick_25MHz <= countto40ns==0;
	bitclk_25MHz <= (countto40ns==3 || countto40ns==0);
    end


    assign uzled = uptime[3:0];
    //assign sr_oe_n = uptime[0];
    //assign uzled = 'b1111;
    // Make 'uptime' register bus-readable at address 0008
    wire [15:0] q0008;
    zror #(16'h0008) r0008(ibus, obus, uptime);
    // Make a register that counts milliseconds since it was last zeroed
    reg [15:0] countms = 0;
    wire [15:0] q0009;
    zror #(16'h0009) r0009(ibus, obus, countms);
    always @ (posedge clk100) begin
	if (bwr && baddr=='h0009) begin
	    countms <= 0;  // zero the count upon write to address 0009
	end else if (tick_1kHz) begin
	    countms <= countms+1;
	end
    end
    wire [15:0] q000a;
    zreg #(16'h000a) r000a(ibus, obus, q000a);
    assign {sr_ds, sr_stcp, sr_stcp0, sr_shcp} = q000a[3:0];
    // assign sr_oe_n = ~q000a[4];
    wire [15:0] q000b = {pgood6, 2'b00, iv_sda1, iv_sda0};
    zror #(16'h000b) r000b(ibus, obus, q000b);
    wire [15:0] q000c;
    wire iv_sda0_out = q000c[0];
    wire iv_sda1_out = q000c[1];
    assign iv_scl0   = q000c[4];
    assign iv_scl1   = q000c[5];
    wire iv_sda0_dir = q000c[8];
    wire iv_sda1_dir = q000c[9];
    zreg #(16'h000c) r000c(ibus, obus, q000c);
    assign iv_sda0 = iv_sda0_dir ? iv_sda0_out : 1'bz;
    assign iv_sda1 = iv_sda1_dir ? iv_sda1_out : 1'bz;
    wire [15:0] q000d;
    zreg #(16'h000d) r000d(ibus, obus, q000d);
    // assign misc_tp   = q000d[0];
    assign tpspare_1 = q000d[1];
    assign tpspare_2 = q000d[2];
    assign tpspare_3 = q000d[3];
    assign tpspare_4 = q000d[4];
    assign tpspare_5 = q000d[5];
    assign tpspare_6 = q000d[6];
    assign sr_oe_n = ~q000d[8];  // 2017-05-03
    wire [15:0] q000e;
    zreg #(16'h000e) r000e(ibus, obus, q000e);
    assign clkdiv_sle  = q000e[8];
    assign clkdiv_sclk = q000e[4];
    assign clkdiv_sdat = q000e[0];
    wire [15:0] q000f;
    zreg #(16'h000f) r000f(ibus, obus, q000f);
    assign clkcln_sle  = q000f[8];
    assign clkcln_sclk = q000f[4];
    assign clkcln_sdat = q000f[0];
    wire [7:0] q0010;
    zreg #(16'h0010,8) r0010(ibus, obus, q0010);
    assign uztoa7 = q0010;
    zror #(16'h0011,7) r0011(ibus, obus, a7touz[7:1]);
    wire [15:0] q0012;
    assign q0012[0] = clkcln_lckdtct;
    assign q0012[3:1] = 3'b0;
    assign q0012[4] = clkdiv_lckdtct;
    assign q0012[15:5] = 11'b0;
    zror #(16'h0012,2) r0012(ibus, obus, q0012);
    // working on "bus" I/O to Artix7
    reg a7_bus_wdat = 0, a7_bus_wdat1 = 0, a7_bus_rdat = 0;
    reg a7_bus_wdat1a = 0, a7_bus_wdat1b = 0;
    wire a7_bus_wdat9;
    wire a7_bus_rdat0;
    zilvds i_a7_bus_rdat (a7_bus_rdat0, bus_rdatp, bus_rdatn);
    zolvds o_a7_bus_wdat (a7_bus_wdat9, bus_wdatp, bus_wdatn);
    always @ (posedge clk100) a7_bus_rdat1 <= a7_bus_rdat0;
    reg a7_bus_rdat1=0, a7_bus_rdat2=0;
    // always @ (posedge clk100_ps1b) a7_bus_rdat1 <= a7_bus_rdat0;
    always @ (posedge clk100) a7_bus_rdat2 <= a7_bus_rdat1;
    always @ (posedge clk100) a7_bus_rdat <= a7_bus_rdat2;

    // see comments for "busfsm" in busio.v
    reg [15:0] bytesseen = 0, bytessent = 0;
    reg [11:0] bytereg = 0;
    reg [39:0] wordreg = 0, lastword = 0;
    reg        execcmd = 0, newrequest = 0;
    reg [49:0] dbgshift = 0;
    always @ (posedge clk100) begin
	dbgshift <= {dbgshift, a7_bus_rdat};
	if (bytereg[11] & !bytereg[1:0]) begin
	    bytesseen <= bytesseen+1;
	    bytereg <= 12'b0;
	    wordreg <= {wordreg[31:0], bytereg[9:2]};
	    execcmd <= bytereg[10];
	end else begin
	    bytereg <= {bytereg[10:0], a7_bus_rdat};
	    if (execcmd) begin
		lastword <= wordreg;
		wordreg <= 40'b0;
	    end else if (newrequest) begin
		lastword <= 40'b0;
	    end
	    execcmd <= 1'b0;
	end
    end
    // registers returning status+data from last A7 bus operation
    wire [7:0]  laststatus = lastword[7:0];
    zror #('h0080,8) r0080(ibus, obus, lastword);
    wire [15:0] lastread   = lastword[23:8];
    zror #('h0081) r0081(ibus, obus, lastread);
    zror #('h0083) r0083(ibus, obus, bytesseen);
    zror #('h0084) r0084(ibus, obus, bytessent);
    // register/FSM to shift a (9-bit) "byte" out to Artix7
    wire [11:0] a7byteout;
    zreg #('h0082,12) r0082(ibus, obus, a7byteout);
    wire r0082_wr = (baddr=='h0082 && bwr && bstrobe);
    reg [3:0] a7byteout_go = 0;
    reg [11:0] a7shiftout = 0;
    always @ (posedge clk100) begin
	a7byteout_go <= {a7byteout_go,r0082_wr};
	if (a7byteout_go==4'b1000) begin
	  a7shiftout <= a7byteout | 'h0200;  // assert start bit
	  bytessent <= bytessent + 1;
	  newrequest <= 1;
	end else begin
	  a7shiftout <= {a7shiftout,1'b0};
	  newrequest <= 0;
	// the OR is a hack to let my testbench overwrite a7_bus_wdat
	end
	a7_bus_wdat1 <= a7_bus_wdat || a7shiftout[11];
	a7_bus_wdat1a <= a7_bus_wdat1;
	a7_bus_wdat1b <= a7_bus_wdat1a;
    end
    reg a7_bus_wdat2 = 0, a7_bus_wdat3 = 0;
    reg a7_bus_wdat4 = 0, a7_bus_wdat5 = 0;
    always @ (posedge clk100_ps1)  a7_bus_wdat2 <= a7_bus_wdat1b;
    always @ (posedge clk100_ps1b) a7_bus_wdat3 <= a7_bus_wdat1b;
    always @ (posedge clk100_ps2)  a7_bus_wdat4 <= a7_bus_wdat1b;
    always @ (posedge clk100_ps3)  a7_bus_wdat5 <= a7_bus_wdat1b;
    assign a7_bus_wdat9 = q000d[13:12]==0 ? a7_bus_wdat3 : 
			  q000d[13:12]==1 ? a7_bus_wdat2 :
			  q000d[13:12]==2 ? a7_bus_wdat4 :
			  q000d[13:12]==3 ? a7_bus_wdat5 : 0 ;
    assign misc_tp = a7_bus_wdat9;


    wire [1:0] 	rofifoflags;
    wire 	rofifo_nempty;
    wire [55:0] rofifo_q;
    reg 	rofifo_bus_ren = 0;
    wire 	rofifo_ren = rofifo_bus_ren; // || rofifo_txfsm_ren;

    // "FIFO reset" signal to clear counters & DAQ FIFOs
    reg        mrb_fifo_reset = 0;
    always @ (posedge clk100) begin
	mrb_fifo_reset <= (bwr && bstrobe && baddr==16'h001e);
    end

    // manual ("bus") readout of FIFO that reads out DRS4 data
    always @ (posedge clk100) begin
	rofifo_bus_ren <= (bwr && bstrobe && baddr==16'h001f && rofifo_nempty);
    end
    zror #('h0020) r0020(ibus, obus,              rofifo_q[15: 0]);
    zror #('h0021) r0021(ibus, obus,              rofifo_q[31:16]);
    zror #('h0022) r0022(ibus, obus,              rofifo_q[47:32]);
    zror #('h0023) r0023(ibus, obus, {rofifoflags,rofifo_q[55:48]});


    // Virtex-5 => Spartan-3AN event readout stream
    wire v5_ro_clk = clk100;
    wire v5_ro_sdat = ro_sdat[0];
    reg  ff_ro_sdat=0;
    reg  ro_got_frame=0, ro_got_frame_delay1=0, ro_got_frame_delay2=0;
    reg [55:0] ro_frame=0, ro_complete_frame=0;
    always @ (posedge v5_ro_clk) begin
	// latch incoming bitstream using source-synchronous clock (100 MHz)
	ff_ro_sdat <= v5_ro_sdat;	   // latch incoming bit stream using
	/*
	 * deserialize:  each 56-bit frame consists of a start bit (=1), then
	 * a zero bit, then a 51-bit payload, then 3 more zero (stop) bits
	 */
	if (mrb_fifo_reset) begin
	    ro_frame <= 0;
	    ro_got_frame <= 0;
	    ro_got_frame_delay1 <= 0;
	    ro_got_frame_delay2 <= 0;
	end else if (ro_frame[55]) begin  // complete frame has been shifted in
	    ro_complete_frame <= ro_frame;
	    ro_frame <= 0;
	    ro_got_frame <= 1;
	    ro_got_frame_delay1 <= 0;
	    ro_got_frame_delay2 <= 0;
	end else begin  // shift in next bit (MSb arrives first)
	    ro_frame <= {ro_frame, ff_ro_sdat};
	    ro_got_frame_delay1 <= ro_got_frame;
	    ro_got_frame_delay2 <= ro_got_frame_delay1;
	    if (ro_got_frame_delay2) ro_got_frame <= 0;
	    // ro_got_frame stays high for 3 clocks, to ease synchronization
	end
    end
    initial $dumpvars(1,ro_frame,ro_complete_frame,ro_got_frame);
    reg  [3:0] ro_gotframe_sync=0;
    reg        ro_gotframe_pulse=0;
    always @ (posedge clk100) begin
	if (mrb_fifo_reset) begin
	    ro_gotframe_sync <= 0;
	    ro_gotframe_pulse <= 0;
	end else begin
	    ro_gotframe_sync <= {ro_gotframe_sync, ro_got_frame};
	    ro_gotframe_pulse <= ro_gotframe_sync[3:2]=='b01;
	end
    end
    wire 	rofifo_nearlyfull, rofifo_sclr;
    wire [11:0] rofifo_nwords;
    fifo4kuz #(.W(56)) rofifo
      (.clk(clk100), .sclr(rofifo_sclr || mrb_fifo_reset),
       .d(ro_complete_frame), .wen(ro_gotframe_pulse),
       .ren(rofifo_ren), .q(rofifo_q), .nempty(rofifo_nempty),
       .nearlyfull(rofifo_nearlyfull), .nwords(rofifo_nwords));
    reg [1:0] 	rofifoflags0 = 0, rofifoflags1 = 0;
    always @ (posedge clk100) begin
	rofifoflags0 <= {rofifo_nempty, rofifo_nearlyfull};
	rofifoflags1 <= rofifoflags0;
    end
    assign rofifoflags = rofifoflags1;
    assign ro_hold = rofifoflags[0]; // rofifo_nearlyfull;
    initial $dumpvars(1,ro_gotframe_pulse,rofifo_nempty,rofifo_nearlyfull);
    reg readout_enable = 0;
    always @ (posedge clk100) readout_enable <= q0003[1];  // was [0] on mrb1
    // this rofifo_sclr register's write semantics are stupid - fixme!
    zreg #('h001b,1) r001b(ibus, obus, rofifo_sclr);
    zror #('h001c)   r001c(ibus, obus, {rofifo_nwords,rofifoflags});

    reg [15:0] 	ro_gotframe_count=0;
    always @ (posedge clk100) begin
	if (mrb_fifo_reset) begin
	    ro_gotframe_count <= 0;
	end else if (bwr && baddr=='h001d) begin
	    ro_gotframe_count <= 0;
	end else if (ro_gotframe_pulse) begin
	    ro_gotframe_count <= ro_gotframe_count+1;
	end
    end
    zror #('h001d) r001d(ibus, obus, ro_gotframe_count);


    wire [15:0] sdac0_word, sdac1_word;
    zreg #('h0140) r0140(ibus, obus, sdac0_word);
    zreg #('h0141) r0141(ibus, obus, sdac1_word);
    reg [4:0] sdac_fsm = 0;
    reg       sdac_which = 0;
    reg       sdac_fsm_go = 0;
    reg [1:0] sdac_syncn_ff = 0;
    reg [15:0] sdac_shiftreg = 0;
    // want to toggle out bits at 25 MHz, which is slower than the
    // 30 MHz maximum bit rate for AD5308 serial DAC interface
    always @ (posedge clk100) begin
	if (sdac_fsm==0 && bstrobe && bwr && (baddr&'hfffe)=='h0140) begin
	    // write to addr 0x0140 or 0x0141: leave idle state
	    sdac_fsm_go <= 1;
	    // addr 0x0140 vs. 0x0141 indicates which of 2 DACs to update
	    sdac_which <= baddr[0];
	end else if (sdac_fsm!=0) begin
	    sdac_fsm_go <= 0;
	end
    end
    always @ (posedge clk100) begin
	if (tick_25MHz) begin
	    // update FSM state register
	    if (sdac_fsm==0 && sdac_fsm_go) begin
		sdac_fsm <= 1;
	    end else if (sdac_fsm>0 && sdac_fsm<18) begin
		// proceed through states 1..18 sequentially
		sdac_fsm <= sdac_fsm+1;
	    end else begin
		sdac_fsm <= 0;
	    end
	    // one of the two SDAC_SYNCN lines is driven low (asserted) during
	    // clock cycles 2..17; otherwise both are high (deasserted)
            if (sdac_fsm>=1 && sdac_fsm<=16) begin
		sdac_syncn_ff <= sdac_which ? 'b01 : 'b10;
	    end else begin
		sdac_syncn_ff <= 'b11;
	    end
	    // 16-bit shift register is loaded during state 1; MSb shifts
	    // through the 16 bits to be driven to DIN line on cycles 2..17
	    if (sdac_fsm==1) begin
		sdac_shiftreg <= sdac_which ? sdac1_word : sdac0_word;
	    end else begin
		sdac_shiftreg <= (sdac_shiftreg << 1);
	    end
	end
    end
    assign sdac_sclk = bitclk_25MHz;
    assign sdac_syncn[1:0] = sdac_syncn_ff[1:0];
    assign sdac_din = sdac_shiftreg[15];



endmodule


// integrated logic analyzer
// module ila_0(clk, probe0)
//   /* synthesis syn_black_box black_box_pad_pin="clk,probe0[31:0]" */;
//     input wire clk;
//     input wire [31:0] probe0;
// endmodule


module bus_zynq_gpio
  (input  wire        clk,
   input  wire        clk100,
   input  wire [31:0] r0, r1, r2,
   output wire [31:0] r3, r4, r5, r6, r7,
   output wire [15:0] baddr,
   output wire        bwr,
   output wire        bstrobe,
   output wire [15:0] bwrdata, 
   input  wire [15:0] brddata
   );
    /*
     * Note for future:  See logbook entries for 2015-05-19 and 05-18.  At 
     * some point I want to make the entire "bus" synchronous to 
     * "mcu_clk100" so that the main FPGA logic all runs off of a single 
     * clock.  When I do that, it may be helpful to use a spare AXI register
     * to allow me to debug the presence of mcu_clk100.
     */

    /*
     * Register assignments:
     *   == read/write by PS (read-only by PL) ==
     *   r0: 32-bit data (reserved for future use)
     *   r1: current operation addr (16 bits) + data (16 bits)
     *   r2: strobe (from PS to PL) + opcode for current operation
     *   == read-only by PS (write-only by PL) ==
     *   r3: status register (includes strobe from PL to PS)
     *   r4: data from last operation (16 bits, may expand to 32)
     *   r5: opcode + addr from last operation
     *   r6: number of "bus" writes (16 bits) + reads (16 bits)
     *   r7: constant 0xfab40001 (could be redefined later)
     */
    // baddr, bwr, bwrdata are output ports of this module whose
    // contents come from the corresponding D-type flipflops.  The
    // "_reg" variable is the FF's "Q" output, and the "_next"
    // variable is the FF's "D" input, which I declare as a "reg" so
    // that its value can be set by a combinational always block.
    // I've added a new "bstrobe" signal to the bus, which could be
    // useful for FIFO R/W or for writing to an asynchronous RAM.
    reg [15:0] baddr_reg=0, baddr_next=0;
    reg [15:0] bwrdata_reg=0, bwrdata_next=0;
    reg        bwr_reg=0, bwr_next=0;
    reg        bstrobe_reg=0, bstrobe_next=0;
    assign baddr = baddr_reg;
    assign bwr = bwr_reg;
    assign bstrobe = bstrobe_reg;
    assign bwrdata = bwrdata_reg;
    // nwr and nrd will be DFFEs that count the number of read and
    // write operations to the bus.  Send results to PS on r6.
    reg [15:0] nwr=0, nrd=0;
    assign r6 = {nwr,nrd};
    // r7 reports to PS this identifying fixed value for now.
    assign r7 = 'hfab40001;
    // These bits of r2 are how the PS tells us to "go" to do the next
    // read or write operation.
    wire ps_rdstrobe = r2[0];  // "read strobe" from PS
    wire ps_wrstrobe = r2[1];  // "write strobe" from PS
    // Make copies of ps_{rd,wr}strobe synchronous to 'clk100'
    reg ps_rdstrobe_clk100_sync = 0;
    reg ps_rdstrobe_clk100 = 0;
    reg ps_wrstrobe_clk100_sync = 0;
    reg ps_wrstrobe_clk100 = 0;
    always @ (posedge clk100) begin
	ps_rdstrobe_clk100_sync <= ps_rdstrobe;
	ps_rdstrobe_clk100 <= ps_rdstrobe_clk100_sync;
	ps_wrstrobe_clk100_sync <= ps_wrstrobe;
	ps_wrstrobe_clk100 <= ps_wrstrobe_clk100_sync;
    end
    // Enumerate the states of the FSM that executes the bus I/O
    localparam 
      FsmStart=0, FsmIdle=1, FsmRead=2, FsmRead1=3,
      FsmWrite=4, FsmWrite1=5, FsmWait=6;
    reg [2:0] fsm=0, fsm_next=0;  // current and next FSM state
    reg       pl_ack=0, pl_ack_next=0;  // "ack" strobe from PL back to PS
    // Make a copy of pl_ack that is synchronous to 'clk'
    reg       pl_ack_clk_sync=0, pl_ack_clk=0;
    always @ (posedge clk) begin
	pl_ack_clk_sync <= pl_ack;
	pl_ack_clk <= pl_ack_clk_sync;
    end
    assign r3 = {fsm, 3'b000, pl_ack_clk};
    reg [31:0] r4_reg=0, r4_next=0;
    assign r4 = r4_reg;
    reg [31:0] r5_reg=0, r5_next=0;
    assign r5 = r5_reg;
    always @(posedge clk100) begin
	fsm <= fsm_next;
	baddr_reg <= baddr_next;
	bwrdata_reg <= bwrdata_next;
	bwr_reg <= bwr_next;
	bstrobe_reg <= bstrobe_next;
	pl_ack <= pl_ack_next;
	r4_reg <= r4_next;
	r5_reg <= r5_next;
	if (fsm==FsmRead1) nrd <= nrd + 1;
	if (fsm==FsmWrite1) nwr <= nwr + 1;
    end
    always @(*) begin
	// these default to staying in same state
	fsm_next = fsm;
	baddr_next = baddr_reg;
	bwrdata_next = bwrdata_reg;
	r4_next = r4_reg;
	r5_next = r5_reg;
	// these default to zero
	bwr_next = 0;
	bstrobe_next = 0;
	pl_ack_next = 0;
	case (fsm)
	    FsmStart: begin
		// Start state: wait for both read and write strobes
		// from PS to be deasserted, then go to Idle state to
		// wait for first bus transaction.
		if (!ps_rdstrobe_clk100 && !ps_wrstrobe_clk100)
		  fsm_next = FsmIdle;
	    end
	    FsmIdle: begin
		// Idle state: When we first arrive here, both read and
		// write strobes from PS should be deasserted.  Wait
		// for one or the other to be asserted, then initiate
		// Read or Write operation, accordingly.
		if (ps_rdstrobe_clk100) begin
		    // Before asserting its "read strobe," the PS
		    // should have already put the target bus address
		    // into r1[15:0].  These go out onto my "bus" on
		    // the next clock cycle.
		    fsm_next = FsmRead;
		    baddr_next = r1[15:0];
		end else if (ps_wrstrobe_clk100) begin
		    // Before asserting its "write strobe," the PS
		    // should have already put the target bus address
		    // into r1[15:0] and the data to be written into
		    // r1[31:16].  These go out onto my "bus" on the
		    // next clock cycle.
		    fsm_next = FsmWrite;
		    baddr_next = r1[15:0];
		    bwrdata_next = r1[31:16];
		    bwr_next = 1;
		end
	    end
	    FsmWrite: begin
		// On this clock cycle, baddr, bwrdata, and bwr are
		// already out on the bus, but no bstrobe yet.
		fsm_next = FsmWrite1;
		bstrobe_next = 1;
		bwr_next = 1;
	    end
	    FsmWrite1: begin
		// bstrobe is asserted for just this clock cycle.  bwr
		// is asserted for both this and previous cycle.  On
		// next cycle, it will be safe to tell the PS that
		// we're done.
		fsm_next = FsmWait;
		r4_next = bwrdata;
		pl_ack_next = 1;
		r5_next = {16'h0002,baddr};
	    end
	    FsmRead: begin
		// On this clock cycle, baddr is already out on the
		// bus, but no bstrobe yet.
		fsm_next = FsmRead1;
		bstrobe_next = 1;
	    end
	    FsmRead1: begin
		// bstrobe is asserted for just this clock cycle.  On
		// the next cycle, it will be safe to tell the PS that
		// we're done and that it can find our answer on r4.
		fsm_next = FsmWait;
		r4_next = brddata;
		pl_ack_next = 1;
		r5_next = {16'h0001,baddr};
	    end
	    FsmWait: begin
		// On this cycle, pl_ack is asserted, informing the PS
		// that we're done with this operation.  We sit here
		// until the PS drops its read or write strobe, thus
		// acknowledging our being done.  Once that happens,
		// we can drop our pl_ack and go to Idle to wait for
		// the next operation.
		pl_ack_next = 1;
		if (!ps_rdstrobe_clk100 && !ps_wrstrobe_clk100) begin
		    pl_ack_next = 0;
		    fsm_next = FsmIdle;
		end
	    end
	    default: begin
		// We somehow find ourselves in an illegal state: 
		// go back to the start state.
		fsm_next = FsmStart;
	    end
	endcase
    end
endmodule

// a read/write register to live on the "bus"
module zreg #( parameter MYADDR=0, W=16, PU=0 )
    (
     input  wire [1+1+16+16-1:0] i,
     output wire [15:0]          o,
     output wire [W-1:0]         q
     );
    wire        clk, wr;
    wire [15:0] addr, wrdata;
    wire [15:0] rddata;
    assign {clk, wr, addr, wrdata} = i;
    assign o = {rddata};
    // boilerplate ends here
    reg [W-1:0] regdat = PU;
    wire addrok = (addr==MYADDR);
    assign rddata = addrok ? regdat : 16'hzzzz;
    always @ (posedge clk)
      if (wr && addrok)
	regdat <= wrdata[W-1:0];
    assign q = regdat;
endmodule // zreg

// a read-only register to live on the "bus"
module zror #( parameter MYADDR=0, W=16 )
    (
     input  wire [1+1+16+16-1:0] i,
     output wire [15:0]          o,
     input  wire [W-1:0]         d
     );
    wire 	clk, wr;
    wire [15:0] addr, wrdata;
    wire [15:0] rddata;
    assign {clk, wr, addr, wrdata} = i;
    assign o = {rddata};
    // boilerplate ends here
    wire addrok = (addr==MYADDR);
    assign rddata = addrok ? d : 16'hzzzz;
endmodule // zror

module zilvds 
  (
   output wire o,
   input  wire i, ib
   );
    IBUFDS #(.DIFF_TERM("TRUE"))
    buffer(.O(o), .I(i), .IB(ib));
endmodule

module zolvds
  (
   input  wire i,
   output wire o, ob
   );
    OBUFDS buffer(.O(o), .OB(ob), .I(i));
endmodule

/*
 * Single-clock 56-bit-wide FIFO, depth 4096 words
 */
module fifo4kuz  #( parameter W=56 )
    (
     input  wire         clk,
     input  wire         sclr,
     input  wire [W-1:0] d,
     input  wire         wen,
     input  wire         ren,
     output wire [W-1:0] q,
     output reg  [11:0]  nwords,
     output wire         nempty,
     output wire         nearlyfull
   );
    initial nwords=0;
    reg  [W-1:0] mem [4095:0];
    reg  [11:0]	 wptr = 0, wptr0 = 0;
    reg  [11:0]	 rptr = 0, rptr0 = 0;
    wire [11:0]  nword = wptr-rptr;
    reg 	 nearlyfullreg = 0, veryfull = 0;
    initial #1 $dumpvars(1,nword);
    assign nempty = (nword!=0);
    assign nearlyfull = nearlyfullreg;
    reg [W-1:0] qreg = 0;
    assign q = qreg;
    always @ (posedge clk) begin
	nwords <= nword;
	if (sclr) {wptr,rptr} <= 0;
	wptr0 <= wptr;
	rptr0 <= rptr;
	if (wen) begin
	    // On write-enable, write word to memory and increment pointer
	    $display("%1d write %m (wptr=%1d) -> %09x", $time, wptr, d);
	    mem[wptr] <= d;
	    wptr <= wptr+1;
	end
	if (ren && nempty) begin
	    $display("%1d read %m (rptr=%1d) > %09x", $time, rptr, mem[rptr]);
	    qreg <= mem[rptr];
	    rptr <= rptr+1;
	end else if (ren) begin
	    $display("%1d read %m when empty *ERROR*", $time);
	    qreg <= 0;
	end
	nearlyfullreg <= (nword[11:9]==3'b111);
	veryfull <= (nword[11:3]==9'h1ff);
    end
endmodule // fifo4kuz

`default_nettype wire

