-- file: clk_rst.vhd
-- 
-- (c) Copyright 2008 - 2013 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
--
------------------------------------------------------------------------------
--  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
--   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
------------------------------------------------------------------------------
-- _cpu_clk____ 8.000______0.000______50.0______145.943_____94.994
-- _vga_clk____25.000______0.000______50.0______169.602_____94.994
--
------------------------------------------------------------------------------
-- Input Clock   Freq (MHz)    Input Jitter (UI)
------------------------------------------------------------------------------
-- __primary_________100.000____________0.010

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity clk_rst is
   port (
      sys_clk_i    : in  std_logic;   -- 100    MHz
      sys_rstn_i   : in  std_logic;
      eth_clk_o    : out std_logic;   --  50    MHz
      vga_clk_o    : out std_logic;   --  25.2  MHz
      main_clk_o   : out std_logic;   --   8.33 MHz
      main_rst_o   : out std_logic;
      pwm_clk_o    : out std_logic;   -- 100    MHz
      ym2151_clk_o : out std_logic;   --   3.57 MHz
      ym2151_rst_o : out std_logic
   );
end clk_rst;

architecture xilinx of clk_rst is

   signal clkfbout_0     : std_logic;
   signal clkfbout_buf_0 : std_logic;
   signal eth_0          : std_logic;
   signal vga_0          : std_logic;
   signal main_0         : std_logic;
   signal pwm_0          : std_logic;
   signal ym2151_0       : std_logic;

   signal ym2151_clk_s   : std_logic;  -- 28.57 MHz
   signal ym2151_cnt_r   : std_logic_vector(2 downto 0);

   signal main_rst_r     : std_logic_vector(3 downto 0) := (others => '1');
   signal ym2151_rst_r   : std_logic_vector(3 downto 0) := (others => '1');

begin

   --------------------------------------
   -- Clocking PRIMITIVE
   --------------------------------------
   -- Instantiation of the MMCM PRIMITIVE
   i_mmcm_adv : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 8.000,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 31.750,    -- VGA @ 25.20 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 16,        -- ETH @ 50.00 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 96,        -- CPU @ 8.33 MHz
         CLKOUT2_PHASE        => 0.000,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => FALSE,
         CLKOUT3_DIVIDE       => 8,         -- PWM @ 100 MHz
         CLKOUT3_PHASE        => 0.000,
         CLKOUT3_DUTY_CYCLE   => 0.500,
         CLKOUT3_USE_FINE_PS  => FALSE,
         CLKOUT4_DIVIDE       => 28,        -- 8*YM2151 @ 28.57 MHz
         CLKOUT4_PHASE        => 0.000,
         CLKOUT4_DUTY_CYCLE   => 0.500,
         CLKOUT4_USE_FINE_PS  => FALSE,
         CLKIN1_PERIOD        => 10.0,
         REF_JITTER1          => 0.010
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfbout_0,
         CLKFBOUTB           => open,
         CLKOUT0             => vga_0,
         CLKOUT0B            => open,
         CLKOUT1             => eth_0,
         CLKOUT1B            => open,
         CLKOUT2             => main_0,
         CLKOUT2B            => open,
         CLKOUT3             => pwm_0,
         CLKOUT3B            => open,
         CLKOUT4             => ym2151_0,
         CLKOUT5             => open,
         CLKOUT6             => open,
         -- Input clock control
         CLKFBIN             => clkfbout_buf_0,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => open,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      );


   -------------------------------------
   -- Output buffering
   -------------------------------------

   clkf_buf : BUFG
      port map (
         I => clkfbout_0,
         O => clkfbout_buf_0
      );

   clkout0_buf : BUFG
      port map (
         I => vga_0,
         O => vga_clk_o
      );

   clkout1_buf : BUFG
      port map (
         I => eth_0,
         O => eth_clk_o
      );

   clkout2_buf : BUFG
      port map (
         I => main_0,
         O => main_clk_o
      );

   clkout3_buf : BUFG
      port map (
         I => pwm_0,
         O => pwm_clk_o
      );

   clkout4_buf : BUFG
      port map (
         I => ym2151_0,
         O => ym2151_clk_s
      );

   p_ym2151_clk : process (ym2151_clk_s)
   begin
      if rising_edge(ym2151_clk_s) then
         ym2151_cnt_r <= ym2151_cnt_r + 1;
      end if;
   end process p_ym2151_clk;

   clkout4a_buf : BUFG
      port map (
         I => ym2151_cnt_r(2),
         O => ym2151_clk_o
      );


   --------------------------------------------------------
   -- Generate reset signal.
   --------------------------------------------------------

   p_main_rst : process (main_clk_o)
   begin
      if rising_edge(main_clk_o) then
         main_rst_r <= main_rst_r(2 downto 0) & "0";  -- Shift left one bit
         if sys_rstn_i = '0' then
            main_rst_r <= (others => '1');
         end if;
      end if;
   end process p_main_rst;

   p_ym2151_rst : process (ym2151_clk_o)
   begin
      if rising_edge(ym2151_clk_o) then
         ym2151_rst_r <= ym2151_rst_r(2 downto 0) & "0";  -- Shift left one bit
         if sys_rstn_i = '0' then
            ym2151_rst_r <= (others => '1');
         end if;
      end if;
   end process p_ym2151_rst;

   main_rst_o   <= main_rst_r(3);
   ym2151_rst_o <= ym2151_rst_r(3);

end xilinx;

