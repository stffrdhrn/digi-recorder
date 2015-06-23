/* Digital recorder controller
   This module interfaces with Buttons, ADC, DAC and SDRAM
   The buttons allow the recorded to switch states
     - Standby
     - Record 
     - Play
     
    In `Record` mode the controller reads data from the ADC and writes it
    to SDRAM
    
    In `Play` mode the controller reads data from the SDRAM and writes to the DAC
    
    In standby mode the recorder doesnt do much of anything
 */
module drec_controller (
  adc_data, adc_enable,
  
  dac_data, dac_enable,
  
  sdram_wr_data,
  sdram_wr_addr,
  sdram_wr_enable,
  
  sdram_rd_data,
  sdram_rd_addr,
  sdram_rd_enable,
  sdram_rd_rdy,
  
  button,
  
  clk, rst_n
);


endmodule