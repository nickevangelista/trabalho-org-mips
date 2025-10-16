library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity somador is
    port(
        somador_in  : in  std_logic_vector(15 downto 0);
        somador_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of somador is
begin
    -- somador combinacional
    somador_out <= std_logic_vector(unsigned(somador_in) + 1);
end architecture;