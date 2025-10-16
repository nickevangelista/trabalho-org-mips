-- Bibliotecas padrão do IEEE
LIBRARY ieee;
USE ieee.std_logic_1164.all;
-- ESSENCIAL para converter o endereço (vetor) para um inteiro
USE ieee.numeric_std.all; 

-- Definição da Entidade "Memoria"
ENTITY memory IS
    GENERIC (
        DATA_WIDTH : integer := 32; -- Largura do dado (32 bits para MIPS)
        ADDR_WIDTH : integer := 10  -- Largura do endereço (10 bits = 2^10 = 1024 posições)
    );
    PORT (
        clk      : IN  std_logic; -- Clock para escrita síncrona
        wr_en    : IN  std_logic; -- '1' para escrever, '0' para ler (Write Enable)
        addr     : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0); -- Endereço
        data_in  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0); -- Dado a ser escrito
        data_out : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)  -- Dado lido da memória
    );
END ENTITY memory;

-- Arquitetura da Memória
ARCHITECTURE rtl OF memory IS

    -- Define o "tamanho" da memória (profundidade) com base na largura do endereço
    constant DEPTH : integer := 2**ADDR_WIDTH; -- Ex: 2^10 = 1024

    -- 1. Define um tipo "array" para ser a nossa memória
    --    É um array de [0 até 1023] onde cada posição guarda um vetor de 32 bits.
    TYPE ram_type IS ARRAY (0 TO DEPTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);

    -- 2. Instancia a memória (RAM) usando o tipo que criamos
    --    Nota: Inicializamos tudo com '0' para facilitar a simulação.
    SIGNAL ram : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN

    -- 3. Processo de Escrita (SÍNCRONO)
    --    Este processo só "enxerga" o clock.
    write_process : PROCESS (clk)
    BEGIN
        -- A escrita só acontece na borda de subida do clock
        IF rising_edge(clk) THEN
            -- E somente se o sinal 'Write Enable' estiver ativo ('1')
            IF wr_en = '1' THEN
                -- Converte o endereço (std_logic_vector) para um inteiro e escreve
                ram(to_integer(unsigned(addr))) <= data_in;
            END IF;
        END IF;
    END PROCESS write_process;

    -- 4. Processo de Leitura (ASSÍNCRONO)
    --    A leitura é combinacional. O dado de saída reflete
    --    imediatamente o conteúdo da posição de memória apontada pelo 'addr'.
    --    Isso bate com seu diagrama, onde a saída da Memória alimenta
    --    um registrador (como o Reg_Inst).
    data_out <= ram(to_integer(unsigned(addr)));

END ARCHITECTURE rtl;