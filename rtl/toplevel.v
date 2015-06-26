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
  input         RESET,

);
// @ 1mhz    19bit (512K) is about 1/2 second
// @ 100mhz  26bit (64M)  is about 1/2 second
localparam DOUBlE_CLICK_WAIT = 19;

wire clk1m1, clk100, clk110;

wire play_btn, rec_btn, btn_rst;
wire dbl_clck_rst_n;

assign dbl_clck_rst_n = RESET & ~btn_rst;

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
  .rst_n(~btn_rst)
);


drec_controller drec_controlleri (
  adc_data, adc_enable,
  
  dac_data, dac_enable,
  
  sdram_wr_data,
  sdram_wr_addr,
  sdram_wr_enable,
  
  sdram_rd_data,
  sdram_rd_addr,
  sdram_rd_enable,
  sdram_rd_data_rdy,
  sdram_rd_data_ack,
  
  .play_btn(play_btn), .rec_btn(rec_btn), .btn_rst(dbl_clck_rst_n),
  
  .clk(clk1m1), .rst_n(RESET)
);
 

wire pwmfifo_empty_n;
wire [15:0] pwm_datain_16b;
wire [7:0]  pwm_datain_8b;

assign pwm_datain_8b = {pwm_datain_16b[15],
                        pwm_datain_16b[13],
                        pwm_datain_16b[11],
                        pwm_datain_16b[9],
                        pwm_datain_16b[7],
                        pwm_datain_16b[5],
                        pwm_datain_16b[3],
                        pwm_datain_16b[1],
                        };
 
fifo pwmfifo (
  .datain(dac_data), .dataout(pwm_datain_16b),
  .clkin(clk1m1), .clkout(clk110),
  .wr(dac_enable), rd,
  //.full(), not read
  .empty_n(),
  
  .rst_n(RESET)
);
 
 module pwmdac(
  .pwmclk(clk110),  /* 110Mhz 44000 x 250 x 10*/
  .sample(pwm_datain_8b),
  input        enable,
 
  .pwmout(GPIO_07)
);

module adc_interface  (
  addr, data,
  din, dout,
  sclk, rst);
  
module sdram_controller (
    /* HOST INTERFACE */
    wr_addr,
    wr_data,
    wr_enable, 

    rd_addr, 
    rd_data,
    rd_ready,
    rd_enable,
    
    busy, rst_n, clk,

    /* SDRAM SIDE */
    addr, bank_addr, data, clock_enable, cs_n, ras_n, cas_n, we_n, data_mask_low, data_mask_high
);

module fifo (
  datain, dataout,
  clkin, clkout,
  wr, rd,
  full, empty_n,
  rst_n
);

kkk


endmodule