LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

-- Entidade de Mem�ria de Porta Dupla (Dual-Port RAM)
-- "1 porta de leitura" (Porta A, para instru��es)
-- "1 porta de leitura/escrita" (Porta B, para dados)
ENTITY memory_dual_port IS
    GENERIC (
        DATA_WIDTH : integer := 32; -- Largura do dado (32 bits)
        ADDR_WIDTH : integer := 10  -- Largura do endere�o (1024 posi��es)
    );
    PORT (
        clk      : IN  std_logic; -- Clock (APENAS para escrita)

        -- Porta A: Leitura de Instru��o (conectada ao PC)
        addr_a   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
        data_out_a : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);

        -- Porta B: Acesso a Dados (conectada � ULA e RegFile)
        addr_b   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
        wr_en_b  : IN  std_logic; -- '1' para escrever, '0' para ler
        data_in_b  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
        data_out_b : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
    );
END ENTITY memory_dual_port;

ARCHITECTURE rtl OF memory_dual_port IS

    constant DEPTH : integer := 2**ADDR_WIDTH; -- 1024 posi��es
    
    -- O array de mem�ria (o "arm�rio" de gavetas)
    TYPE ram_type IS ARRAY (0 TO DEPTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
    
    -- Instancia a mem�ria. Em FPGAs reais, isso se torna um Bloco de RAM (BRAM)
    -- 'shared variable' � frequentemente usada para RAMs dual-port para simula��o
    SHARED VARIABLE ram : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN

    -- Processo de Escrita (Porta B)
    -- A escrita � s�ncrona (s� acontece na borda do clock)
    write_process_B : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF wr_en_b = '1' THEN
                ram(to_integer(unsigned(addr_b))) := data_in_b;
            END IF;
        END IF;
    END PROCESS write_process_B;

    -- Leitura (Porta A) - Ass�ncrona
    -- Conectada ao PC para buscar instru��es
    read_process_A : PROCESS (addr_a)
    BEGIN
        data_out_a <= ram(to_integer(unsigned(addr_a)));
    END PROCESS read_process_A;

    -- Leitura (Porta B) - Ass�ncrona
    -- Conectada � ULA para 'lw'
    read_process_B : PROCESS (addr_b, wr_en_b)
    BEGIN
        -- IMPORTANTE: Para evitar ler e escrever ao mesmo tempo
        -- n�s s� lemos se o 'wr_en' for '0'.
        IF wr_en_b = '0' THEN
             data_out_b <= ram(to_integer(unsigned(addr_b)));
        END IF;
    END PROCESS read_process_B;
    
    -- Nota: O c�digo acima infere uma RAM "Read-first".
    -- Modelos mais complexos podem ser "Write-first".
    -- Para um processador MIPS, isso � suficiente.

END ARCHITECTURE rtl;