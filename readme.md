## Digital Audio Recorder

The heart is in fpga. Needs an ADC, speaker and sdram like those found in 
De0 Nano. 

## Compontent Timings

### ADC
Running at 1.1 Mhz
(Top speed 3.2Mhz)

 - 1 sample every 16 cycles
 - 4 samples
 - 44000 samples every second
    16 x 4 x 44000 -> 2816000  - cannot implement on PLL
             44100 -> 2822400  - cannot implement on PLL 



### DAC - 110Mhz
 (8-bit sample every 44000 hz)
 10 x 8-bit duty cycle (250) x 44000 -> 
   
### Recorder Controller - 1.1Mhz
 (sample every 25 cycles -> 44Hz)

### Double Click        - 1.1Mhz

### SDRAM                - 100Mhz

# Todo
 - clk and rst_n for all circuits
