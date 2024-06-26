-- Ethan Griesman
-- Department of Electrical and Computer Engineering
-- Iowa State University
-- Spring 2024
--------------------------------------------------------------------------------------


-- ALU.vhd
--------------------------------------------------------------------------------------
-- DESCRIPTION: 32 bit full ALU with barrel shifter
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.NUMERIC_STD.ALL; -- To use unsigned types

entity ALU is
   port(
          inputA       : in std_logic_vector(31 downto 0);  -- Operand 1
          inputB       : in std_logic_vector(31 downto 0);  -- Operand 2
          i_shamt      : in std_logic_vector(4 downto 0);   -- shift amount
          opSelect     : in std_logic_vector(8 downto 0);   -- Op Select
          overflowEn   : in std_logic;                      -- overflow enable
          resultOut    : out std_logic_vector(31 downto 0); -- Result F
          overflow     : out std_logic;                     -- Overflow
          carryOut     : out std_logic;                     -- Carry out
          zeroOut      : out std_logic  -- 1 when resultOut = 0 Zero
     );
end ALU;

architecture structure of ALU is

     -- 32-bit add/sub module 
     component n_addsub is
     generic (N : integer := 32);
          port(i_A      : in std_logic_vector(31 downto 0);
               i_B      : in std_logic_vector(31 downto 0);
               i_C      : in std_logic;
               o_Sum    : out std_logic_vector(31 downto 0);
               oC      : out std_logic;
               oOF      : out std_logic
          ); --Change to add previous carry as output in order to XOR for overflow
     end component;

     -- 32-bit barrelShifter
     component barrelShifter
          port (
            iDir            : in std_logic;                       -- Right or Left shift
            iSra            : in std_logic; -- 1->signExtend 0->zeroExtend
            ishamt          : in std_logic_vector(4 downto 0);   -- Shift amount
            iInput          : in std_logic_vector(31 downto 0);  -- Input data
            oOutput         : out std_logic_vector(31 downto 0)  -- Output
          );
     end component;

     -- OR GATE --
     component org2 is
          port(i_A	: in std_logic;
               i_B	: in std_logic;
               o_F	: out std_logic);
     end component;

     -- AND GATE --
     component andg2 is
          port(i_A	: in std_logic;
               i_B	: in std_logic;
               o_F	: out std_logic);
     end component;

     -- XOR GATE -- 
     component xorg2 is
          port(i_A          : in std_logic;
               i_B          : in std_logic;
               o_F          : out std_logic);
     end component;
     
     -- INVERT --
     component onesComp is
          generic(N : integer := 32);
          port(i_D: in std_logic_vector(N-1 downto 0);
               o_O: out std_logic_vector(N-1 downto 0));
     end component;

        -- Bitwise signals --
        signal s_and                  :  std_logic_vector(31 downto 0); --done
        signal s_or                   :  std_logic_vector(31 downto 0); 
        signal s_xor                  :  std_logic_vector(31 downto 0);
        signal s_not                  :  std_logic_vector(31 downto 0);
        signal s_nor                  :  std_logic_vector(31 downto 0);

        -- Arithmetic signals --
        signal s_sum                  :  std_logic_vector(31 downto 0); -- add or sub depending on control signals
        signal s_minus                :  std_logic; -- set to 1 to make adder subtract instead of add
        signal s_carry                :  std_logic;                     -- for fullAdder output

        -- Shifter signals --
        signal s_shift                :  std_logic_vector(31 downto 0);
        signal s_sra                  :  std_logic;
        signal s_dir                  :  std_logic;
        signal s_shamt                :  std_logic_vector(4 downto 0); -- ammount of shifts to perform

        -- Misc signals --    
        signal s_slt                  :  std_logic_vector(31 downto 0); -- slt
        signal s_sltSum               :  std_logic;                     -- slt sum
        signal s_sltC                 :  std_logic_vector(31 downto 0); -- slt carry
        signal s_lui                  :  std_logic_vector(31 downto 0); -- lui result

        -- ALU signal
        signal s_resultout            :  std_logic_vector(31 downto 0); -- result out
        signal s_zero                 :  std_logic;

        -- Overflow signal --
        signal s_overflowCheck        :  std_logic;
        signal s_overflow             :  std_logic;
        
        begin

          --------------
          -- BITWISE ---
          --------------

          -- AND -- --done
          ALU_AND: for i in 0 to 31 generate
           ANDGS: andg2
           port map(i_A => inputA(i),
                    i_B => inputB(i),
                    o_F => s_and(i));
          end generate ALU_AND;

          -- OR -- --done
          ALU_OR: for i in 0 to 31 generate
           ORGS: org2
           port map(i_A => inputA(i),
                    i_B => inputB(i), 
                    o_F => s_or(i));
          end generate ALU_OR;

          -- XOR -- --done
          ALU_XOR: for i in 0 to 31 generate
           XORGS: xorg2
           port map(i_A => inputA(i),
                    i_B => inputB(i),
                    o_F => s_xor(i));
          end generate ALU_XOR;
          
          -- NOR -- --done
          ALU_NOR: onesComp
          generic map (32)
          port map(i_D => s_or,
                   o_O => s_nor);

          -- NOT -- --done
          ALU_NOT: onesComp
          generic map(32)
          port map(i_D => inputA,
                   o_O => s_not);
                   
          --------------
          -- ADD SUB ---
          --------------

          -- generate minus signal --
          with opSelect select
          s_minus <= '1' when "100000000",  -- Assuming this opSelect value corresponds to subtraction
                     '0' when others;  -- Default to addition for other cases

          -- ADD SUB --
          adderN : n_addsub
           port map(i_A => inputA,      -- inputA
                    i_B => inputB,      -- inputB
                    i_C => s_minus,     -- control bit to determine add or sub
                    o_Sum => s_sum,     -- sum output
                    oC => s_carry,      -- carry
                    oOF => s_overflow); -- carry30 xor carry31     

          --------------
          -- SHIFTING --
          --------------

           -- Connect the barrel shifter
           ALU_SHIFTER: barrelShifter
           port map(
                    iDir   => s_dir,
                    iSra   => s_sra,
                    ishamt => s_shamt,
                    iInput => inputB,
                    oOutput => s_shift
               );

          -- direction generation: 0 for left, 1 for right --          
          with opSelect select
              s_dir <= '0' when "000000001" | "000100001",  -- SLL, SLLV
                       '1' when "000001001" | "000101001" | "010001001" | "010101001",  -- SRL, SRLV, SRA, SRAV
                       '0' when others;  -- Default to left shift

          -- 0 for logical, 1 for arithmetic
          with opSelect select
              s_sra <= '0' when "000000001" | "000001001" | "000100001" | "000101001",  -- Logical shifts
                       '1' when "010001001" | "010101001",  -- Arithmetic shifts (SRA, SRAV)
                       '0' when others;

          -- shift amount, shift type (logical/arithmetic)
          with opSelect select
              s_shamt <= i_shamt when "000000001" | "000001001" | "010001001",  -- SLL, SRL, SRA
                         inputA(4 downto 0) when "000100001" | "000101001" | "010101001",  -- SLLV, SRLV, SRAV
                         "10000" when "001000001",                                        -- LUI
                         (others => '0') when others;

          s_lui <= inputB(15 downto 0) & x"0000";

          -- SLT --
          ALU_SLT: n_addsub
           port map(i_A => inputA,
                    i_B => inputB,
                    i_C => '1',           -- Subtraction for SLT
                    oC => s_sltSum,
                    o_Sum => s_sltC,
                    oOF   => open);

          -- Extract the most significant bit (sign bit) from the subtraction result
          -- least significant
          s_slt(31 downto 1) <= (others => '0');  -- Initialize to all zeros
          s_slt(0) <= s_sltC(31);   -- Set the sign bit


          --MUX for output--
          with opSelect select  --diff than add sub
          s_resultout <= s_sum when "000000000", --add  
                         s_sum when "100000000", --sub
                         s_and when   "000000011", --and
                         s_or when    "000000010", --or
                         s_xor when   "000000100", --xor
                         s_nor when   "000010010", --nor
                         s_slt when   "100000101", --slt
                         s_shift when "000000001" , --sll
                         s_shift when "000001001", --srl
                         s_shift when "010001001", --sra
                         s_shift when "000100001", --sllv
                         s_shift when "000101001", --srlv
                         s_shift when "010101001", --srav
                         s_lui when "001000001", --lui
                         "11111111111111111111111111111111" when others;

          -- Zero flag logic --
          with s_resultout select
            s_zero <= '1' when "00000000000000000000000000000000",
                      '0' when others;

          -- Assign outputs --
          resultOut <= s_resultout;
          zeroOut <= s_zero;
          carryOut <= s_carry;


          overflow <= s_overflow AND overflowEN;


end structure;
        
    