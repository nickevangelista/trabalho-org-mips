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
    -- === INÍCIO DO PROGRAMA (Endereço 0) ===
        
        -- 1. SETUP: Carregar valores
        0 => x"40180000", -- LW R1, [512]  -> R1 = 10 (0xA)
        1 => x"40280400", -- LW R2, [513]  -> R2 = 5  (0x5)
        
        -- 2. ARITMÉTICA (R-Type)
        2 => x"01230000", -- ADD R3, R1, R2 -> R3 = 10 + 5 = 15 (0xF)
        3 => x"21240000", -- SUB R4, R1, R2 -> R4 = 10 - 5 = 5  (0x5)
        
        -- 3. MEMÓRIA (Store Normal)
        -- Salva o resultado do ADD (R3=15) no endereço 514
        -- End 514 (0x202) -> Bits 19-10: 10 0000 0010 -> Hex digitos: 8 0 8
        4 => x"50380800", -- STORE R3, [514] -> Mem[514] = 15
        
        -- 4. INSTRUÇÃO CUSTOMIZADA (SADD)
        -- SADD R1, R2, [515]. Soma R1(10) + R2(5) = 15 e salva no endereço 515.
        -- End 515 (0x203) -> Bits 19-10: 10 0000 0011 -> Hex digitos: 8 0 C
        5 => x"31280C00", -- SADD: Mem[515] = 10 + 5
        
        -- 5. BRANCH (BEQ)
        -- Compara R1(10) com R1(10). São iguais. Deve pular para instrução 8.
        -- End 8 (0x008) -> Bits 19-10: 00 0000 1000 -> Hex digitos: 0 2 0
        6 => x"61102800", -- BEQ R1, R1, para Endereço 10
        
        -- 6. INSTRUÇÃO "LIXO" (Deve ser pulada se o BEQ funcionar)
        7 => x"21110000", -- SUB R1, R1, R1 -> Se executar, R1 vira 0 (ERRO!)

        -- 7. ALVO DO BRANCH e JUMP
        -- Endereço 8. Vamos fazer um JUMP para travar o processador aqui (Loop Infinito)
        -- JUMP para endereço 8.
        10 => x"80280000", -- JUMP 10 (Loop infinito)

        -- === DADOS ===
        512 => x"0000000A", -- Valor 10
        513 => x"00000005", -- Valor 5
        
        others => (others => '0')
    );
begin
    --data_out <= mem(to_integer(unsigned(addr)));
    --data_out <= mem(to_integer(unsigned(addr)));
    process(clk)
    begin
        
        if rising_edge(clk) then
            data_out <= mem(to_integer(unsigned(addr)));
            -- leitura síncrona/ troquei pra assincrona por causa do problema do clock
            
            
            -- escrita (se habilitada)
            if verifica_escrita = '1' then
                mem(to_integer(unsigned(addr))) <= data_in;
            end if;

        end if;
    end process;

end architecture behavioral;