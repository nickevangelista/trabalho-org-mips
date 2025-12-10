library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Reg_file is
    Port (
        clk                  : in  std_logic;
        rst                  : in  std_logic;
        escreve_reg          : in  std_logic;                           -- sinal de controle 
        leitura_rs           : in  std_logic_vector(3 downto 0);        -- registrador rs
        leitura_rt           : in  std_logic_vector(3 downto 0);        -- registrador rt
        endereco_escrita     : in  std_logic_vector(3 downto 0);        -- endereço de escrita
        escreve_dado         : in  std_logic_vector(31 downto 0);       -- dado a ser gravado
        leitura_dado1        : out std_logic_vector(31 downto 0);       -- saída dado 1 para ULA
        leitura_dado2        : out std_logic_vector(31 downto 0)        -- saída dado 2 para ULA
    );
end Reg_file;

architecture Behavioral of Reg_file is

    type reg_array is array (0 to 15) of std_logic_vector(31 downto 0);     --16 registradores de 32 bits
    signal registradores : reg_array := (others => (others => '0'));        -- inicializa com zero todos
begin

    process(clk, rst)
    begin
        if rst = '1' then
            registradores <= (others => (others => '0'));
        elsif rising_edge(clk) then -- Escreve
            if escreve_reg = '1' and to_integer(unsigned(endereco_escrita)) /= 0 then 
                registradores(to_integer(unsigned(endereco_escrita))) <= escreve_dado;
            end if;
        end if;
    end process;

    -- leitura dos registradores
    leitura_dado1 <= registradores(to_integer(unsigned(leitura_rs)));
    leitura_dado2 <= registradores(to_integer(unsigned(leitura_rt)));

end Behavioral;