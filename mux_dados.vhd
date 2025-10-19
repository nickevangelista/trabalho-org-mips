library ieee;
use ieee.std_logic_1164.all;

entity mux_data is
    port(
        alu_in  : in  std_logic_vector(31 downto 0);  -- dado vindo da ULA
        mem_in  : in  std_logic_vector(31 downto 0);  -- dado vindo da mem�ria (Reg_Data)
        sel     : in  std_logic;                      -- seletor do mux  --> 0 vem da ULA, 1 vem da mem�ria
        mux_out : out std_logic_vector(31 downto 0)   -- sa�da selecionada
    );
end entity;

architecture rtl of mux_data is
begin
    -- MUX 2:1 (escolhe entre ULA e Mem�ria)
    mux_out <= alu_in when sel = '0' else
               mem_in;
end architecture;