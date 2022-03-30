// adc_qsys.v

// Generated using ACDS version 20.1 720

`timescale 1 ps / 1 ps
module adc_qsys (
		input  wire        clk_clk,                //        clk.clk
		output wire        clk_200mhz_clk,         // clk_200mhz.clk
		output wire        clk_50mhz_clk,          //  clk_50mhz.clk
		input  wire        command_valid,          //    command.valid
		input  wire [4:0]  command_channel,        //           .channel
		input  wire        command_startofpacket,  //           .startofpacket
		input  wire        command_endofpacket,    //           .endofpacket
		output wire        command_ready,          //           .ready
		input  wire        reset_reset_n,          //      reset.reset_n
		output wire        response_valid,         //   response.valid
		output wire [4:0]  response_channel,       //           .channel
		output wire [11:0] response_data,          //           .data
		output wire        response_startofpacket, //           .startofpacket
		output wire        response_endofpacket    //           .endofpacket
	);

	wire    pll0_c0_clk;                        // PLL0:c0 -> ADC_0:adc_pll_clock_clk
	wire    pll0_c1_clk;                        // PLL0:c1 -> [ADC_0:clock_clk, rst_controller:clk]
	wire    pll0_locked_conduit_export;         // PLL0:locked -> ADC_0:adc_pll_locked_export
	wire    rst_controller_reset_out_reset;     // rst_controller:reset_out -> ADC_0:reset_sink_reset_n
	wire    rst_controller_001_reset_out_reset; // rst_controller_001:reset_out -> PLL0:reset

	adc_qsys_ADC_0 adc_0 (
		.clock_clk              (pll0_c1_clk),                     //          clock.clk
		.reset_sink_reset_n     (~rst_controller_reset_out_reset), //     reset_sink.reset_n
		.adc_pll_clock_clk      (pll0_c0_clk),                     //  adc_pll_clock.clk
		.adc_pll_locked_export  (pll0_locked_conduit_export),      // adc_pll_locked.export
		.command_valid          (command_valid),                   //        command.valid
		.command_channel        (command_channel),                 //               .channel
		.command_startofpacket  (command_startofpacket),           //               .startofpacket
		.command_endofpacket    (command_endofpacket),             //               .endofpacket
		.command_ready          (command_ready),                   //               .ready
		.response_valid         (response_valid),                  //       response.valid
		.response_channel       (response_channel),                //               .channel
		.response_data          (response_data),                   //               .data
		.response_startofpacket (response_startofpacket),          //               .startofpacket
		.response_endofpacket   (response_endofpacket)             //               .endofpacket
	);

	adc_qsys_PLL0 pll0 (
		.clk                (clk_clk),                            //       inclk_interface.clk
		.reset              (rst_controller_001_reset_out_reset), // inclk_interface_reset.reset
		.read               (),                                   //             pll_slave.read
		.write              (),                                   //                      .write
		.address            (),                                   //                      .address
		.readdata           (),                                   //                      .readdata
		.writedata          (),                                   //                      .writedata
		.c0                 (pll0_c0_clk),                        //                    c0.clk
		.c1                 (pll0_c1_clk),                        //                    c1.clk
		.c2                 (clk_50mhz_clk),                      //                    c2.clk
		.c3                 (clk_200mhz_clk),                     //                    c3.clk
		.locked             (pll0_locked_conduit_export),         //        locked_conduit.export
		.scandone           (),                                   //           (terminated)
		.scandataout        (),                                   //           (terminated)
		.c4                 (),                                   //           (terminated)
		.areset             (1'b0),                               //           (terminated)
		.phasedone          (),                                   //           (terminated)
		.phasecounterselect (3'b000),                             //           (terminated)
		.phaseupdown        (1'b0),                               //           (terminated)
		.phasestep          (1'b0),                               //           (terminated)
		.scanclk            (1'b0),                               //           (terminated)
		.scanclkena         (1'b0),                               //           (terminated)
		.scandata           (1'b0),                               //           (terminated)
		.configupdate       (1'b0)                                //           (terminated)
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (1),
		.OUTPUT_RESET_SYNC_EDGES   ("deassert"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller (
		.reset_in0      (~reset_reset_n),                 // reset_in0.reset
		.clk            (pll0_c1_clk),                    //       clk.clk
		.reset_out      (rst_controller_reset_out_reset), // reset_out.reset
		.reset_req      (),                               // (terminated)
		.reset_req_in0  (1'b0),                           // (terminated)
		.reset_in1      (1'b0),                           // (terminated)
		.reset_req_in1  (1'b0),                           // (terminated)
		.reset_in2      (1'b0),                           // (terminated)
		.reset_req_in2  (1'b0),                           // (terminated)
		.reset_in3      (1'b0),                           // (terminated)
		.reset_req_in3  (1'b0),                           // (terminated)
		.reset_in4      (1'b0),                           // (terminated)
		.reset_req_in4  (1'b0),                           // (terminated)
		.reset_in5      (1'b0),                           // (terminated)
		.reset_req_in5  (1'b0),                           // (terminated)
		.reset_in6      (1'b0),                           // (terminated)
		.reset_req_in6  (1'b0),                           // (terminated)
		.reset_in7      (1'b0),                           // (terminated)
		.reset_req_in7  (1'b0),                           // (terminated)
		.reset_in8      (1'b0),                           // (terminated)
		.reset_req_in8  (1'b0),                           // (terminated)
		.reset_in9      (1'b0),                           // (terminated)
		.reset_req_in9  (1'b0),                           // (terminated)
		.reset_in10     (1'b0),                           // (terminated)
		.reset_req_in10 (1'b0),                           // (terminated)
		.reset_in11     (1'b0),                           // (terminated)
		.reset_req_in11 (1'b0),                           // (terminated)
		.reset_in12     (1'b0),                           // (terminated)
		.reset_req_in12 (1'b0),                           // (terminated)
		.reset_in13     (1'b0),                           // (terminated)
		.reset_req_in13 (1'b0),                           // (terminated)
		.reset_in14     (1'b0),                           // (terminated)
		.reset_req_in14 (1'b0),                           // (terminated)
		.reset_in15     (1'b0),                           // (terminated)
		.reset_req_in15 (1'b0)                            // (terminated)
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (1),
		.OUTPUT_RESET_SYNC_EDGES   ("deassert"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_001 (
		.reset_in0      (~reset_reset_n),                     // reset_in0.reset
		.clk            (clk_clk),                            //       clk.clk
		.reset_out      (rst_controller_001_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_in1      (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_in2      (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);

endmodule
