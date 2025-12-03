library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity memoria is
    port (
        clk                    : in  std_logic;
        verifica_escrita       : in  std_logic;                         -- verifica se sera escrito algo na memoria
        addr                   : in  std_logic_vector(9 downto 0);      -- endereco
        data_in                : in  std_logic_vector(31 downto 0);     -- para quando for ser escrito um dado na memoria
        data_out               : out std_logic_vector(31 downto 0)      -- para quando for ser lido um dado na memoria
    );
end memoria;

architecture behavioral of memoria is

    type mem_tipo is array (0 to 1023) of std_logic_vector(31 downto 0);

    
    signal mem : mem_tipo :=
    (
    -- Instruções (0 até 511) -- Valores para realizar o testbench
        0 => x"40188000",  -- LW R1, [512] 
        1 => x"4028C000",  -- LW R2, [513] 
        2 => x"01230000",  -- ADD R3 = R1 + R2 
        3 => x"5038A000",  -- SW R3, [520] 

    -- DADOS (endereços 512 e 513)
        512 => x"0000000A", -- valor 10
        513 => x"00000005", -- valor 5

        others => (others => '0')
    );
begin
    data_out <= mem(to_integer(unsigned(addr)));
    process(clk)
    begin
        
        if rising_edge(clk) then
        
            -- leitura síncrona/ troquei pra assincrona por causa do problema do clock
            
            
            -- escrita (se habilitada)
            if verifica_escrita = '1' then
                mem(to_integer(unsigned(addr))) <= data_in;
            end if;

        end if;
    end process;

end architecture behavioral;