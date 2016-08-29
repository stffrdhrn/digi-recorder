/**
 * This pulse width modulator DAC is supposed to work with a
 * parameterized sample width.  Based on the sample with
 * it would create the proper counter sizes to create the PWM
 * circuit. 
 *
 * The duty cycle will be center balanced. This requires double
 * the time to generate the duty cycle because it count up and
 * down for each pulse. 
 *
 * The clock frequency must be provided as per the following 
 * formula. 
 *
 * 2^(SAMPLE_WIDTH) x 2 x PULSE_PER_SAMPLE x SAMPLE_PER_SECOND
 *  
 * - SAMPLE_WIDTH - bit width of samples (i.e. 12, 8, 6)
 * - PULSE_PER_SAMPLE - how many pulses to generate for each sample (i.e. 1,2)
 * - SAMPLE_PER_SECOND - how often the same will change (i.e. hifi 44K hz)
 *
 * AUTHOR: Stafford Horne
 *
 * */
module pwmdac (
  sample,
  pwmout,
  
  clk,
  rst_n
);

parameter SAMPLE_WIDTH   = 8;
parameter CLK_FREQ       = 32;
parameter PWM_PER_CYLCLE = 4;

input [SAMPLE_WIDTH-1:0] sample;
output                   pwmout;
input                    clk, rst_n;

reg  [SAMPLE_WIDTH-1:0]  sample_ff;
reg  [7:0]               pwm_dutycyc_ff; /* keeps count of duty cycle (250hz) */
reg  [3:0]               pwm_outcnt_ff; /* keeps count of ouputs per sample (10) */

assign pwmout = (sample_ff > pwm_dutycyc_ff);

always @ (posedge clk)
  if (~rst_n) 
    begin
    sample_ff <= 0;
    pwm_dutycyc_ff = 8'd0;
    pwm_outcnt_ff = 4'd0;
    end
  else
    begin
    pwm_dutycyc_ff <= pwm_dutycyc_ff + 1'b1;  
  
    if (!pwm_dutycyc_ff) 
      if (pwm_outcnt_ff == 4'd3) 
        begin
        sample_ff <= sample;
        pwm_outcnt_ff <= 4'd0;
        end 
      else
        pwm_outcnt_ff <= pwm_outcnt_ff + 1'b1;

    end
    
endmodule
