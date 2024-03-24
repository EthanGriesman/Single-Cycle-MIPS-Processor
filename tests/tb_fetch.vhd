-------------------------------------------------------------------------
-- Ethan Griesman
-- CPR E 381 Spring 24
-- Iowa State University
-------------------------------------------------------------------------
-- tb_fetch.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a testbench for a fetch_logic.
--  
--Notes            
--by Ethan Griesman
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_fetch is
  generic(
    gCLK_HPER   : time := 10 ns  -- Generic for half of the clock cycle period
  );
end tb_fetch;

architecture arch of tb_fetch is

  --define the total clock period time
  constant cCLK_PER : time := gCLK_HPER * 2;
  
  component fetch is 
    port (
      iRST      : in std_logic;
      iRSTVAL   : in std_logic_vector(31 downto 0);
      iAddr     : in std_logic_vector(25 downto 0);
      iSignExtendImm : in std_logic_vector(31 downto 0);
      iBranch   : in std_logic;
      iALUZero  : in std_logic;
      iJump     : in std_logic;
      oPC       : out std_logic_vector(31 downto 0);
      oPCPlus4  : out std_logic_vector(31 downto 0)
    );
  end component;

-- Create signals for all of the inputs and outputs of the file that you are testing
  signal iCLK, reset : std_logic := '0';

  signal s_Rst, s_RstVal, s_Addr, s_SignExtendImm : std_logic_vector(31 downto 0);
  signal s_Branch, s_ALUZero, s_Jump : std_logic;
  signal s_PC, s_PCPlus4 : std_logic_vector(31 downto 0);

begin 

  DUT0: fetch
    port map(
      iRST      => s_Rst,
      iRSTVAL   => s_RstVal,
      iAddr     => s_Addr,
      iSignExtendImm => s_SignExtendImm,
      iBranch   => s_Branch,
      iALUZero  => s_ALUZero,
      iJump     => s_Jump,
      oPC       => s_PC,
      oPCPlus4  => s_PCPlus4
    );
				  
 --This first process is to setup the clock for the test bench
  P_CLK: process
  begin
    iCLK <= '1';         -- clock starts at 1
    wait for gCLK_HPER; -- after half a cycle
    iCLK <= '0';         -- clock becomes a 0 (negative edge)
    wait for gCLK_HPER; -- after half a cycle, process begins evaluation again
  end process;
  
  -- This process resets the sequential components of the design.
  -- It is held to be 1 across both the negative and positive edges of the clock
  -- so it works regardless of whether the design uses synchronous (pos or neg edge)
  -- or asynchronous resets.
  P_RST: process
  begin
    reset <= '0';   
    wait for gCLK_HPER/2;
    reset <= '1';
    wait for gCLK_HPER*2;
    reset <= '0';
    wait;
  end process;
  
  -- Assign inputs for each test case.
  P_TEST_CASES: process
  begin
    wait for gCLK_HPER/2; -- for waveform clarity, NOT changing inputs on clk edges
    
    -- Test case 1:
    s_Addr <= x"000000a0";
    s_Rst <= '0';
    s_RstVal <= (others => '0');
    s_SignExtendImm <= (others => '0');
    s_Branch <= '0';
    s_ALUZero <= '0';
    s_Jump <= '0';
    wait for cCLK_PER; -- Wait for one clock cycle
  end process;
  
end arch;