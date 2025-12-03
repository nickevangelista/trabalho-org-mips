library IEEE;
use IEEE.std_logic_1164.all;

entity mux_data is
    port(
        alu_in       : in  std_logic_vector(31 downto 0);       -- dado vindo da ULA_OUT
        mem_in       : in  std_logic_vector(31 downto 0);       -- dado vindo da memória (reg_data)
        sel          : in  std_logic;                           -- seletor, 1 da ula_out, 0 do reg_data
        mux_data_out : out std_logic_vector(31 downto 0)        -- saída do dado selecionada
    );
end mux_data;

architecture behavioral of mux_data is
begin
    mux_data_out <= alu_in when sel = '1' else
               mem_in;
end architecture;