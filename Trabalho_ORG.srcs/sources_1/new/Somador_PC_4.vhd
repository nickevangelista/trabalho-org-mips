library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity somador_PC_4 is
    port(
        somador_in  : in  std_logic_vector(9 downto 0); -- Instrução anterior
        somador_out : out std_logic_vector(9 downto 0)  -- Próxima instrução
    );
end entity;

architecture behavioral of somador_PC_4 is -- Soma +1 para pegar a próxima
begin
    somador_out <= std_logic_vector(unsigned(somador_in) + 1);
end architecture;