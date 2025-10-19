library ieee;
use ieee.std_logic_1164.all;

entity mux_pc is
    port(
        pc_plus4    : in  std_logic_vector(31 downto 0); -- caminho normal (PC + 4)
        branch_addr : in  std_logic_vector(31 downto 0); -- endereço de desvio (ex: PC + offset << 2)
        jump_target : in  std_logic_vector(31 downto 0); -- endereço para instruções de salto (J)
        zero_flag   : in  std_logic;                     -- flag do subtrator (1 se A == B)
        is_branch   : in  std_logic;                     -- sinal da UC para BEQ
        is_jump     : in  std_logic;                     -- sinal da UC para JUMP
        pc_next     : out std_logic_vector(31 downto 0)  -- saída: próximo valor do PC
    );
end entity;

architecture rtl of mux_pc is
begin
    process(pc_plus4, branch_addr, jump_target, zero_flag, is_branch, is_jump)
    begin
        if is_jump = '1' then
            pc_next <= jump_target;                 -- salto incondicional (J)
        elsif is_branch = '1' and zero_flag = '1' then
            pc_next <= branch_addr;                 -- desvio condicional (BEQ verdadeiro)
        else
            pc_next <= pc_plus4;                    -- fluxo normal (PC + 4)
        end if;
    end process;
end architecture;
