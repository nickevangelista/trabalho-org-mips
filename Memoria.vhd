-- memory_dual_port.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memory_dual_port IS
    GENERIC (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 10
    );
    PORT (
        clk      : IN  std_logic;
        addr_a   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
        data_out_a : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
        addr_b   : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
        wr_en_b  : IN  std_logic;
        data_in_b  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
        data_out_b : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
    );
END ENTITY memory_dual_port;

ARCHITECTURE rtl OF memory_dual_port IS

    constant DEPTH : integer := 2**ADDR_WIDTH;
    TYPE ram_type IS ARRAY (0 TO DEPTH - 1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);

    -- Use signal to represent RAM (synthesizable)
    SIGNAL ram : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN

    -- Escrita síncrona (porta B)
    Processo_Escrita_B : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF wr_en_b = '1' THEN
                ram(to_integer(unsigned(addr_b))) <= data_in_b;
            END IF;
        END IF;
    END PROCESS Processo_Escrita_B;

    -- Leitura assíncrona porta A (instruções)
    Processo_Leitura_A : PROCESS (addr_a, ram)
    BEGIN
        data_out_a <= ram(to_integer(unsigned(addr_a)));
    END PROCESS Processo_Leitura_A;

    -- Leitura porta B: só disponibiliza dado quando não está escrevendo
    Processo_Leitura_B : PROCESS (addr_b, wr_en_b, ram)
    BEGIN
        IF wr_en_b = '0' THEN
            data_out_b <= ram(to_integer(unsigned(addr_b)));
        ELSE
            -- Durante escrita, podemos escolher apresentar valor indefinido ou o dado que está sendo escrito.
            -- Aqui, escolhemos apresentar o dado escrito (comportamento que facilita algumas simulações).
            data_out_b <= data_in_b;
        END IF;
    END PROCESS Processo_Leitura_B;

END ARCHITECTURE rtl;
