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


endmodule