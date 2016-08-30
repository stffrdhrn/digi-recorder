module toplevel (
   
  input         btn_n_pad_i, // KEY 1
  
  /* SDRAM INTERFACE */
  output [1:0]  sdram_ba_pad_o,
  output [12:0] sdram_a_pad_o,
  inout  [15:0] sdram_dq_pad_io,
  output [1:0]  sdram_dqm_pad_o,
  output        sdram_cas_pad_o,
  output        sdram_ras_pad_o,
  output        sdram_we_pad_o,
  
  output        sdram_cs_n_pad_o,
  output        sdram_cke_pad_o,
  output        sdram_clk_pad_o,
  
  /* ADC INTERFACE */
  output        spi1_sck_o,
  output        spi1_ss_o,
  input         spi1_miso_i,
  output        spi1_mosi_o,

  
  /* DIP SWITCHES */
  input [3:0]   gpio1_i,
  
  /* LEDS */
  output [7:0]  gpio0_io,
  
  /* SPEAKER OUT */
  output        pwm1_o,
  output        spi3_ss_o,
  output        spi3_sck_o,
  output        spi3_mosi_o,
  
  input         sys_clk_pad_i,
  input         rst_n_pad_i  // KEY 0

);
// @ 1mhz    19bit (512K) is about 1/2 second
// @ 100mhz  26bit (64M)  is about 1/2 second
localparam DOUBlE_CLICK_WAIT = 19;

wire clk1m1, clk100, pwmclk;

wire play_btn, rec_btn, btn_ack;
wire dbl_clck_rst_n;

wire [15:0] dac_data;
wire        dac_enable;

//                      0        0  0 
//                      0        1  0 
//                      1        0  1
//                      1        1  0
assign dbl_clck_rst_n = rst_n_pad_i & ~btn_ack;

pll plli (
  .inclk0    (sys_clk_pad_i), 
  .c0        (clk100), 
  .c1        (clk1m1), 
  .c2        ()
);

pwmpll pwmplli (
  .inclk0    (sys_clk_pad_i), 
  .c0        (pwmclk)
);

double_click #(.WAIT_WIDTH(DOUBlE_CLICK_WAIT)) double_clicki (
  .button   (~btn_n_pad_i), 
  .single   (play_btn), 
  .double   (rec_btn),  
  .clk      (clk1m1), 
  .rst_n    (dbl_clck_rst_n)
);

wire [15:0] sdram_wr_data;
wire [23:0] sdram_wr_addr;
wire        sdram_wr_enable;

wire [15:0] sdram_rd_data;
wire [23:0] sdram_rd_addr;
wire        sdram_rd_enable;
wire        sdram_rd_data_rdy;
wire        sdram_rd_data_ack;

drec_controller drec_controlleri (
  .adc_data          ({4'b0000, adc_dataout_12b}),
  .adc_enable        (),
  
  .dac_data          (dac_data),
  .dac_enable        (dac_enable),
  
  .sdram_wr_addr     (sdram_wr_addr),
  .sdram_wr_data     (sdram_wr_data),
  .sdram_wr_enable   (sdram_wr_enable),
  
  .sdram_rd_data     (sdram_rd_data),
  .sdram_rd_addr     (sdram_rd_addr),
  .sdram_rd_enable   (sdram_rd_enable),
  .sdram_rd_data_rdy (sdram_rd_data_rdy),
  .sdram_rd_data_ack (sdram_rd_data_ack),
  
  .ctl_play          (play_btn),
  .ctl_rec           (rec_btn), 
  .ctl_ack           (btn_ack),
  
  .display           (gpio0_io),
  
  .clk               (clk1m1), 
  .rst_n             (rst_n_pad_i)
);
 

/* PWM ADAPTER */
// Adapting fifo output to the PWM input
wire  pwm_read;
reg   pwm_read_ack;
wire  pwmfifo_empty_n;
wire [15:0] pwm_datain_16b;
reg  [7:0]  pwm_datain_8b_r;

                        
always @ (posedge pwmclk)
if (~rst_n_pad_i) 
  begin
  pwm_read_ack <= 1'b0;
  pwm_datain_8b_r <= 8'd0;
  end
else
  begin
  pwm_read_ack <= pwm_read;
  if (pwm_read)
    pwm_datain_8b_r <= pwm_datain_16b[11:4];
  end
/* DONE PWM ADAPTER */
 
fifo pwmfifo (
  .wr_data(dac_data), 
  .wr(dac_enable),
  .full(), //not read
  .wr_clk(clk1m1), 
  
  .rd_data(pwm_datain_16b),
  .rd(pwm_read_ack),
  .empty_n(pwm_read),
  .rd_clk(pwmclk),
  
  .rst_n(rst_n_pad_i)
);
 
pwmdac daci (
  .sample(pwm_datain_8b_r),
  .pwmout(pwm1_o),
  
  .clk(pwmclk),  /* 110Mhz 44000 x 250 x 10*/
  .rst_n(rst_n_pad_i)  // TODO it would be nice to only enable DAC during PLAY
);

dacspi dacspidi (
  .wr_data({4'b0001, dac_data[11:0]}),
  .wr(dac_enable),
  
  .spi_cs_n(spi3_ss_o),    // white
  .spi_sclk(spi3_sck_o),   // yellow
  .spi_sdout(spi3_mosi_o), // blue
  
  .clk(clk1m1),  /* 110Mhz 44000 x 250 x 10*/
  .rst_n(rst_n_pad_i)  // TODO it would be nice to only enable DAC during PLAY
);

wire [ 11:0] adc_dataout_12b;
assign       spi1_sck_o = clk1m1;
  
adcspi adci (
  .data  (adc_dataout_12b),
  .cs_n  (spi1_ss_o), 
  .din   (spi1_miso_i),
  .dout  (spi1_mosi_o),
  .clk   (clk1m1), 
  .rst_n (rst_n_pad_i));

assign sdram_clk_pad_o = clk100;

wire [23:0] wr_addr;
wire [15:0] wr_data;
wire        wr_enable;
wire        busy;

wire [23:0] rd_addr;
wire [15:0] rd_data;
wire        rd_enable;
wire        rd_ready;

sdram_controller sdram_controlleri (
    /* HOST INTERFACE */
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .wr_enable(wr_enable), 

    .rd_addr(rd_addr), 
    .rd_data(rd_data),
    .rd_ready(rd_ready),
    .rd_enable(rd_enable),
    
    .busy(busy), .rst_n(rst_n_pad_i), .clk(clk100),

    /* SDRAM SIDE */
    .addr          (sdram_a_pad_o),
    .bank_addr     (sdram_ba_pad_o),
    .data          (sdram_dq_pad_io),
    .clock_enable  (sdram_cke_pad_o), 
    .cs_n          (sdram_cs_n_pad_o),
    .ras_n         (sdram_ras_pad_o),
    .cas_n         (sdram_cas_pad_o),
    .we_n          (sdram_we_pad_o), 
    .data_mask_low (sdram_dqm_pad_o[0]), 
    .data_mask_high(sdram_dqm_pad_o[1])
);


fifo #(.BUS_WIDTH(24 + 16)) wr_fifoi (
  // recorder ctl domain
  .wr_data({sdram_wr_addr, sdram_wr_data}), 
  .wr(sdram_wr_enable), 
  .full(),   // TODO could be used to indicate sdram is busy
  .wr_clk(clk1m1), 
  // SDRAM domain
  .rd_data({wr_addr, wr_data}),
  .rd(busy),
  .empty_n(wr_enable),
  .rd_clk(clk100),
  
  .rst_n(rst_n_pad_i)
);

fifo #(.BUS_WIDTH(24)) rd_addrfifoi (
  // recorder ctl domain
  .wr_data(sdram_rd_addr), 
  .wr(sdram_rd_enable), 
  .full(),   // TODO could be used to indicate sdram is busy
  .wr_clk(clk1m1), 
  // SDRAM domain
  .rd_data(rd_addr),
  .rd(busy),
  .empty_n(rd_enable),
  .rd_clk(clk100),
  
  .rst_n(rst_n_pad_i)
);

fifo #(.BUS_WIDTH(16)) rd_datafifoi (
  // recorder ctl domain
  .rd_data(sdram_rd_data),
  .rd(sdram_rd_data_ack),
  .empty_n(sdram_rd_data_rdy),
  .rd_clk(clk1m1),
  // SDRAM domain
  .wr_data(rd_data), 
  .wr(rd_ready), 
  .full(),
  .wr_clk(clk100), 
    
  .rst_n(rst_n_pad_i)
);
endmodule
