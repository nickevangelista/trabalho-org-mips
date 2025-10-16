-- Importa as bibliotecas b�sicas do VHDL
LIBRARY ieee;
USE ieee.std_logic_1164.all; -- Para o tipo std_logic
USE ieee.numeric_std.all;    -- Para opera��es matem�ticas com vetores

-------------------------------------------------------------------------------
-- ENTIDADE: memory_dual_port
-- Descri��o: Define uma mem�ria RAM com duas "portas" de acesso independentes.
-- Porta A: Ser� usada S� PARA LEITURA (buscar instru��es).
-- Porta B: Ser� usada para LEITURA E ESCRITA (acessar dados).
-------------------------------------------------------------------------------
ENTITY memory_dual_port IS
    GENERIC (
        DATA_WIDTH : integer := 32; -- Largura de cada "gaveta" da mem�ria (32 bits)
        ADDR_WIDTH : integer := 10  -- Largura do endere�o (10 bits = 1024 gavetas)
    );
    PORT (
        clk      : IN  std_logic; -- Clock, usado APENAS para a opera��o de ESCRITA

        -- Porta A (Leitura de Instru��o): Conectada ao PC
        addr_a   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0); -- Endere�o de leitura A
        data_out_a : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0); -- Dado que sai pela porta A

        -- Porta B (Acesso a Dados): Conectada � ULA
        addr_b   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0); -- Endere�o de acesso B
        wr_en_b  : IN  std_logic; -- Habilita Escrita na porta B ('1'=escreve, '0'=l�)
        data_in_b  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0); -- Dado que ENTRA para ser escrito
        data_out_b : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)  -- Dado que SAI pela porta B
    );
END ENTITY memory_dual_port;

-- ARQUITETURA (Define o funcionamento interno da mem�ria)
ARCHITECTURE rtl OF memory_dual_port IS

    -- Define a profundidade (n�mero de posi��es) da mem�ria
    constant DEPTH : integer := 2**ADDR_WIDTH; -- 2^10 = 1024 posi��es
    
    -- 1. Cria um "tipo de dado" que � um array (vetor de vetores).
    --    Este ser� o formato do nosso "arm�rio" de mem�ria.
    TYPE ram_type IS ARRAY (0 TO DEPTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
    
    -- 2. Instancia a mem�ria (o "arm�rio") usando o tipo criado acima.
    --    'SHARED VARIABLE' � o jeito padr�o de criar uma mem�ria que pode ser
    --    acessada por m�ltiplos processos, como � o caso aqui.
    --    Inicializamos tudo com '0' para a simula��o n�o mostrar valores 'U' (indefinido).
    SHARED VARIABLE ram : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN -- In�cio da l�gica

    ---------------------------------------------------------------------------
    -- L�GICA DA PORTA B (ESCRITA)
    ---------------------------------------------------------------------------
    -- A opera��o de escrita � S�NCRONA (controlada pelo clock)
    Processo_Escrita_B : PROCESS (clk)
    BEGIN
        -- Acontece apenas na borda de subida do clock
        IF rising_edge(clk) THEN
            -- E somente se o sinal de habilita��o de escrita estiver em '1'
            IF wr_en_b = '1' THEN
                -- Converte o endere�o para inteiro e armazena o dado de entrada na RAM.
                ram(to_integer(unsigned(addr_b))) := data_in_b;
            END IF;
        END IF;
    END PROCESS Processo_Escrita_B;

    ---------------------------------------------------------------------------
    -- L�GICA DA PORTA A (LEITURA)
    ---------------------------------------------------------------------------
    -- A opera��o de leitura � ASS�NCRONA (n�o depende do clock)
    Processo_Leitura_A : PROCESS (addr_a)
    BEGIN
        -- O dado de sa�da reflete instantaneamente o conte�do da posi��o de mem�ria
        -- apontada pelo endere�o 'addr_a'.
        data_out_a <= ram(to_integer(unsigned(addr_a)));
    END PROCESS Processo_Leitura_A;

    ---------------------------------------------------------------------------
    -- L�GICA DA PORTA B (LEITURA)
    ---------------------------------------------------------------------------
    -- A leitura na Porta B tamb�m � ASS�NCRONA
    Processo_Leitura_B : PROCESS (addr_b, wr_en_b)
    BEGIN
        -- IMPORTANTE: Para garantir que a porta B n�o tente ler e escrever
        -- ao mesmo tempo, a leitura s� � permitida se a escrita estiver DESATIVADA.
        IF wr_en_b = '0' THEN
             data_out_b <= ram(to_integer(unsigned(addr_b)));
        END IF;
    END PROCESS Processo_Leitura_B;

END ARCHITECTURE rtl;
