library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux_Pc1 is
    Port(
        endereco_beq_jmp : in  STD_LOGIC_VECTOR(9 downto 0);   -- endereço de BEQ ou JUMP
        pc_4             : in  STD_LOGIC_VECTOR(9 downto 0);   -- incremento do pc
        verifica_beq     : in  STD_LOGIC;                      -- verifica se o beq é igual a 1
        verifica_jmp     : in  STD_LOGIC;                      -- verifica se o jmp é igual a 1
        pc_out           : out STD_LOGIC_VECTOR(9 downto 0)    -- valor final enviado ao PC
    );
end Mux_Pc1;

architecture Behavioral of Mux_Pc1 is
begin

    pc_out <= endereco_beq_jmp when verifica_jmp = '1' else
              endereco_beq_jmp when verifica_beq = '1' else
              pc_4;

end Behavioral;