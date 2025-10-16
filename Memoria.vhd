-- Bibliotecas padr�o do IEEE
LIBRARY ieee;
USE ieee.std_logic_1164.all;
-- ESSENCIAL para converter o endere�o (vetor) para um inteiro
USE ieee.numeric_std.all; 

-- Defini��o da Entidade "Memoria"
ENTITY memory IS
    GENERIC (
        DATA_WIDTH : integer := 32; -- Largura do dado (32 bits para MIPS)
        ADDR_WIDTH : integer := 10  -- Largura do endere�o (10 bits = 2^10 = 1024 posi��es)
    );
    PORT (
        clk      : IN  std_logic; -- Clock para escrita s�ncrona
        wr_en    : IN  std_logic; -- '1' para escrever, '0' para ler (Write Enable)
        addr     : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0); -- Endere�o
        data_in  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0); -- Dado a ser escrito
        data_out : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)  -- Dado lido da mem�ria
    );
END ENTITY memory;

-- Arquitetura da Mem�ria
ARCHITECTURE rtl OF memory IS

    -- Define o "tamanho" da mem�ria (profundidade) com base na largura do endere�o
    constant DEPTH : integer := 2**ADDR_WIDTH; -- Ex: 2^10 = 1024

    -- 1. Define um tipo "array" para ser a nossa mem�ria
    --    � um array de [0 at� 1023] onde cada posi��o guarda um vetor de 32 bits.
    TYPE ram_type IS ARRAY (0 TO DEPTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);

    -- 2. Instancia a mem�ria (RAM) usando o tipo que criamos
    --    Nota: Inicializamos tudo com '0' para facilitar a simula��o.
    SIGNAL ram : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN

    -- 3. Processo de Escrita (S�NCRONO)
    --    Este processo s� "enxerga" o clock.
    write_process : PROCESS (clk)
    BEGIN
        -- A escrita s� acontece na borda de subida do clock
        IF rising_edge(clk) THEN
            -- E somente se o sinal 'Write Enable' estiver ativo ('1')
            IF wr_en = '1' THEN
                -- Converte o endere�o (std_logic_vector) para um inteiro e escreve
                ram(to_integer(unsigned(addr))) <= data_in;
            END IF;
        END IF;
    END PROCESS write_process;

    -- 4. Processo de Leitura (ASS�NCRONO)
    --    A leitura � combinacional. O dado de sa�da reflete
    --    imediatamente o conte�do da posi��o de mem�ria apontada pelo 'addr'.
    --    Isso bate com seu diagrama, onde a sa�da da Mem�ria alimenta
    --    um registrador (como o Reg_Inst).
    data_out <= ram(to_integer(unsigned(addr)));

END ARCHITECTURE rtl;