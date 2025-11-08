library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity subtrator_beq is
    port(
        a      : in  std_logic_vector(31 downto 0);  -- valor do registrador A
        b      : in  std_logic_vector(31 downto 0);  -- valor do registrador B
        result : out std_logic_vector(31 downto 0);  -- resultado da subtração
        zero   : out std_logic                       -- flag: 1 se resultado = 0
    );
end entity;

architecture rtl of subtrator_beq is
    signal sub_res : signed(31 downto 0);
begin
    -- subtração combinacional (A - B)
    sub_res <= signed(a) - signed(b);
    result  <= std_logic_vector(sub_res);

    -- flag de igualdade
    zero <= '1' when sub_res = 0 else '0';
end architecture;