library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux_MEM is
    Port(
        sel        : in  STD_LOGIC_VECTOR (1 downto 0); -- seletor do mux
        reg_inst_in: in  STD_LOGIC_VECTOR (9 downto 0); -- entrada do endereco do load para salvar em um registrador (00)
        pc_in      : in  STD_LOGIC_VECTOR (9 downto 0); -- entrada para o pc pegar a proxima instrução ou desviar (01)
        reg_b_in   : in  STD_LOGIC_VECTOR (9 downto 0); -- entrada para pegar o endereco do store vindo do reg_b (10)
        addr_out   : out STD_LOGIC_VECTOR (9 downto 0)  -- saida para o addr da memoria
        );
end Mux_MEM;

architecture Behavioral of Mux_MEM is
begin

    with sel select
        addr_out <= reg_inst_in when "00",
                    pc_in       when "01",
                    reg_b_in    when "10",
                    (others => '0') when others;

end Behavioral;