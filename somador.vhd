library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity somador is
    port(
        somador_in  : in  std_logic_vector(31 downto 0);
        somador_out : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of somador is
begin
    -- somador combinacional: PC + 4 (tava antes PC + 1)
    somador_out <= std_logic_vector(unsigned(somador_in) + 4);
end architecture;