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
        -- == INSTRUÇÕES == 
        
        0 => x"40180000", -- LW R1, [512]   -> R1 = 10 (0xA)
        1 => x"40280400", -- LW R2, [513]   -> R2 = 5  (0x5)
        2 => x"01230000", -- ADD R3, R1, R2 -> R3 = 10 + 5 = 15 (0xF)
        3 => x"21240000", -- SUB R4, R1, R2 -> R4 = 10 - 5 = 5  (0x5)
        4 => x"50380800", -- STORE R3, [514] -> Mem[514] = 15
        5 => x"31280C00", -- SADD R1, R2, [515]. Soma R1(10) + R2(5) = 15 e salva no endereço 515.
        6 => x"61102800", -- BEQ R1, R1, para Endereço 10
        
        7 => x"21110000", -- instrução lixo, para verificar se o BEQ ta funcionando

        10 => x"80280000", -- JUMP 10 , fica em um loop em 10


        -- === DADOS ===
        512 => x"00000008", -- 8
        513 => x"00000005", -- 5
        
        others => (others => '0')
    );
begin
    process(clk)
    begin
        
        if rising_edge(clk) then                                -- leitura síncrona
            data_out <= mem(to_integer(unsigned(addr)));

            
            
          
            if verifica_escrita = '1' then                      -- escrita 
                mem(to_integer(unsigned(addr))) <= data_in;
            end if;

        end if;
    end process;

end architecture behavioral;