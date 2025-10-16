-- Importa as bibliotecas básicas do VHDL
LIBRARY ieee;
USE ieee.std_logic_1164.all; -- Para o tipo std_logic
USE ieee.numeric_std.all;    -- Para operações matemáticas com vetores

-------------------------------------------------------------------------------
-- ENTIDADE: memory_dual_port
-- Descrição: Define uma memória RAM com duas "portas" de acesso independentes.
-- Porta A: Será usada SÓ PARA LEITURA (buscar instruções).
-- Porta B: Será usada para LEITURA E ESCRITA (acessar dados).
-------------------------------------------------------------------------------
ENTITY memory_dual_port IS
    GENERIC (
        DATA_WIDTH : integer := 32; -- Largura de cada "gaveta" da memória (32 bits)
        ADDR_WIDTH : integer := 10  -- Largura do endereço (10 bits = 1024 gavetas)
    );
    PORT (
        clk      : IN  std_logic; -- Clock, usado APENAS para a operação de ESCRITA

        -- Porta A (Leitura de Instrução): Conectada ao PC
        addr_a   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0); -- Endereço de leitura A
        data_out_a : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0); -- Dado que sai pela porta A

        -- Porta B (Acesso a Dados): Conectada à ULA
        addr_b   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0); -- Endereço de acesso B
        wr_en_b  : IN  std_logic; -- Habilita Escrita na porta B ('1'=escreve, '0'=lê)
        data_in_b  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0); -- Dado que ENTRA para ser escrito
        data_out_b : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)  -- Dado que SAI pela porta B
    );
END ENTITY memory_dual_port;

-- ARQUITETURA (Define o funcionamento interno da memória)
ARCHITECTURE rtl OF memory_dual_port IS

    -- Define a profundidade (número de posições) da memória
    constant DEPTH : integer := 2**ADDR_WIDTH; -- 2^10 = 1024 posições
    
    -- 1. Cria um "tipo de dado" que é um array (vetor de vetores).
    --    Este será o formato do nosso "armário" de memória.
    TYPE ram_type IS ARRAY (0 TO DEPTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
    
    -- 2. Instancia a memória (o "armário") usando o tipo criado acima.
    --    'SHARED VARIABLE' é o jeito padrão de criar uma memória que pode ser
    --    acessada por múltiplos processos, como é o caso aqui.
    --    Inicializamos tudo com '0' para a simulação não mostrar valores 'U' (indefinido).
    SHARED VARIABLE ram : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN -- Início da lógica

    ---------------------------------------------------------------------------
    -- LÓGICA DA PORTA B (ESCRITA)
    ---------------------------------------------------------------------------
    -- A operação de escrita é SÍNCRONA (controlada pelo clock)
    Processo_Escrita_B : PROCESS (clk)
    BEGIN
        -- Acontece apenas na borda de subida do clock
        IF rising_edge(clk) THEN
            -- E somente se o sinal de habilitação de escrita estiver em '1'
            IF wr_en_b = '1' THEN
                -- Converte o endereço para inteiro e armazena o dado de entrada na RAM.
                ram(to_integer(unsigned(addr_b))) := data_in_b;
            END IF;
        END IF;
    END PROCESS Processo_Escrita_B;

    ---------------------------------------------------------------------------
    -- LÓGICA DA PORTA A (LEITURA)
    ---------------------------------------------------------------------------
    -- A operação de leitura é ASSÍNCRONA (não depende do clock)
    Processo_Leitura_A : PROCESS (addr_a)
    BEGIN
        -- O dado de saída reflete instantaneamente o conteúdo da posição de memória
        -- apontada pelo endereço 'addr_a'.
        data_out_a <= ram(to_integer(unsigned(addr_a)));
    END PROCESS Processo_Leitura_A;

    ---------------------------------------------------------------------------
    -- LÓGICA DA PORTA B (LEITURA)
    ---------------------------------------------------------------------------
    -- A leitura na Porta B também é ASSÍNCRONA
    Processo_Leitura_B : PROCESS (addr_b, wr_en_b)
    BEGIN
        -- IMPORTANTE: Para garantir que a porta B não tente ler e escrever
        -- ao mesmo tempo, a leitura só é permitida se a escrita estiver DESATIVADA.
        IF wr_en_b = '0' THEN
             data_out_b <= ram(to_integer(unsigned(addr_b)));
        END IF;
    END PROCESS Processo_Leitura_B;

END ARCHITECTURE rtl;
