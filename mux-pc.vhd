library ieee;
use ieee.std_logic_1164.all;

entity pc_mux is
    port (
        pc_plus1    : in  std_logic_vector(15 downto 0); -- caminho normal
        jump_target : in  std_logic_vector(15 downto 0); -- usado em JMP
        branch_addr : in  std_logic_vector(15 downto 0); -- usado em JEQ, JBG, JLR
        flag        : in  std_logic;                     -- flag da ULA (zero/greater/less, conforme UC)
        is_jump     : in  std_logic;                     -- sinal da UC
        is_branch   : in  std_logic;                     -- sinal da UC
        pc_next     : out std_logic_vector(15 downto 0)  -- pr?ximo PC
    );
end entity;

architecture rtl of pc_mux is
begin
    process(pc_plus1, jump_target, branch_addr, flag, is_jump, is_branch)
    begin
        if is_jump = '1' then
            pc_next <= jump_target;         -- JMP incondicional
        elsif is_branch = '1' and flag = '1' then
            pc_next <= branch_addr;         -- branch condicional atendido
        else
            pc_next <= pc_plus1;            -- fluxo normal
        end if;
    end process;
end architecture;