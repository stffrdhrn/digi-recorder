module toplevel (
   
  input         BUTTON,
  
  /* SDRAM INTERFACE */
  output [1:0]  DRAM_BA,
  output [12:0] DRAM_ADDR,
  inout  [15:0] DRAM_DQ,
  output [1:0]  DRAM_DQM,
  output        DRAM_CAS_N,
  output        DRAM_RAS_N,
  output        DRAM_WE_N,
  
  output        DRAM_CS_N,
  output        DRAM_CKE,
  output        DRAM_CLK,
  
  /* ADC INTERFACE */
  output        ADC_CLK,
  output        ADC_CS_N,
  input         ADC_IN,
  output        ADC_OUT,

  
  /* SPEAKER OUT */
  output        GPIO_07,
  
  input         CLOCK_50,
  input         RESET

);
// @ 1mhz    19bit (512K) is about 1/2 second
// @ 100mhz  26bit (64M)  is about 1/2 second
localparam DOUBlE_CLICK_WAIT = 19;

wire clk1m1, clk100, clk110;

wire play_btn, rec_btn, btn_ack;
wire dbl_clck_rst_n;

wire [15:0] dac_data;
wire        dac_enable;


//                      0        0  0 
//                      0        1  0 
//                      1        0  1
//                      1        1  0
assign dbl_clck_rst_n = RESET & ~btn_ack;

pll plli (
  .inclk0(CLOCK_50), 
  .c0(clk100), 
  .c1(clk1m1), 
  .c2(clk110)
);

double_click #(.WAIT_WIDTH(DOUBlE_CLICK_WAIT)) double_clicki (
  .button(~BUTTON), 
  .single(play_btn), 
  .double(rec_btn),  
  .clk(clk1m1), 
  .rst_n(dbl_clck_rst_n)
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
  .adc_data({4'b0000, adc_dataout_12b}), .adc_enable(),
  
  .dac_data(dac_data), .dac_enable(dac_enable),
  
  .sdram_wr_addr(sdram_wr_addr),
  .sdram_wr_data(sdram_wr_data),
  .sdram_wr_enable(sdram_wr_enable),
  
  .sdram_rd_data(sdram_rd_data),
  .sdram_rd_addr(sdram_rd_addr),
  .sdram_rd_enable(sdram_rd_enable),
  .sdram_rd_data_rdy(sdram_rd_data_rdy),
  .sdram_rd_data_ack(sdram_rd_data_ack),
  
  .ctl_play(play_btn), .ctl_rec(rec_btn), .ctl_ack(btn_ack),
  
  .clk(clk1m1), .rst_n(RESET)
);
 

/* PWM ADAPTER */
// Adapting fifo output to the PWM input
wire  pwm_read;
reg   pwm_read_ack;
wire  pwmfifo_empty_n;
wire [15:0] pwm_datain_16b;
wire [7:0]  pwm_datain_8b;
reg  [7:0]  pwm_datain_8b_r;

assign pwm_datain_8b = {pwm_datain_16b[15], pwm_datain_16b[13], pwm_datain_16b[11], pwm_datain_16b[9],
                        pwm_datain_16b[7], pwm_datain_16b[5], pwm_datain_16b[3], pwm_datain_16b[1]};
                        
always @ (posedge clk110)
if (~RESET) 
  begin
  pwm_read_ack <= 1'b0;
  pwm_datain_8b_r <= 8'd0;
  end
else
  begin
  pwm_read_ack <= pwm_read;
  if (pwm_read)
    pwm_datain_8b_r <= pwm_datain_8b;
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
  .rd_clk(clk110),
  
  .rst_n(RESET)
);
 
pwmdac daci (
  .pwmclk(clk110),  /* 110Mhz 44000 x 250 x 10*/
  .sample(pwm_datain_8b_r),
  .enable(RESET),  // TODO it would be nice to only enable DAC during PLAY
  .pwmout(GPIO_07)
);

wire [ 11:0] adc_dataout_12b;
assign       ADC_CLK = clk1m1;
  
adcspi adci (
  .data(adc_dataout_12b),
  .cs_n(ADC_CS_N), 
  .din(ADC_IN),
  .dout(ADC_OUT),
  .clk(clk1m1), 
  .rst_n(RESET));

assign DRAM_CLK = clk100;

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
    
    .busy(busy), .rst_n(RESET), .clk(clk100),

    /* SDRAM SIDE */
    .addr(DRAM_ADDR), .bank_addr(DRAM_BA), .data(DRAM_DQ), .clock_enable(DRAM_CKE), 
    .cs_n(DRAM_CS_N), .ras_n(DRAM_RAS_N), .cas_n(DRAM_CAS_N), .we_n(DRAM_WE_N), 
    .data_mask_low(DRAM_DQM[0]), .data_mask_high(DRAM_DQM[1])
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
  
  .rst_n(RESET)
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
  
  .rst_n(RESET)
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
    
  .rst_n(RESET)
);
endmodule