library IEEE;
use IEEE.std_logic_1164.all;

entity nbit_ripple_adder is
    generic (N : integer := 16);
    port (
        i_A   : in std_logic_vector(N - 1 downto 0);
        i_B   : in std_logic_vector(N - 1 downto 0);
        i_C   : in std_logic;
        o_Sum : out std_logic_vector(N - 1 downto 0);
        o_Cm  : out std_logic;
        o_C   : out std_logic
    );
end nbit_ripple_adder;

architecture structural of nbit_ripple_adder is
    component full_adder is
        port (
            i_A   : in std_logic;
            i_B   : in std_logic;
            i_C   : in std_logic;
            o_Sum : out std_logic;
            o_C   : out std_logic
        );
    end component;

    signal carries : std_logic_vector(0 to N);

begin

    carries(0) <= i_C;

    G_NBit_Adder : for i in 0 to N - 1 generate
        AdderI : full_adder
        port map(
            i_A(i),
            i_B(i),
            carries(i),
            o_Sum(i),
            carries(i + 1)
        );
    end generate;

    o_C <= carries(N);
    o_Cm <= carries(N - 1);

end structural;
