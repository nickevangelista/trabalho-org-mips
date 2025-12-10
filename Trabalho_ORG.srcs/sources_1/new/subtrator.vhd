library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity subtrator is
    port(
            a           : in  std_logic_vector(31 downto 0);  -- valor do registrador A
            b           : in  std_logic_vector(31 downto 0);  -- valor do registrador B
            zero_beq    : out std_logic                       -- sinal se deu zero para verificar BEQ               
        );
end subtrator;

architecture behavioral of subtrator is
    signal sub_res : signed(31 downto 0);
begin
    sub_res <= signed(a) - signed(b);   
    zero_beq <= '1' when sub_res = 0 else '0';

end architecture;