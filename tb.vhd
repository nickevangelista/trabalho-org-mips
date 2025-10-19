library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity toplevel_tb is
end toplevel_tb;

architecture Behavioral of toplevel_tb is

    -- 1. Component Declaration for the Unit Under Test (UUT)
    --    Isso DEVE ser id�ntico � 'entity' do seu toplevel.vhd
    component toplevel
        port (
            clk : IN  std_logic;
            rst : IN  std_logic
        );
    end component;

    -- 2. Signals for the testbench
    signal tb_clk : std_logic := '0'; -- Sinal do Clock
    signal tb_rst : std_logic := '1'; -- Sinal do Reset (come�a em '1')

    -- 3. Clock period definition
    constant CLOCK_PERIOD : time := 10 ns; -- Define um clock de 100 MHz (10 ns)

begin

    -- 4. Instantiate the Unit Under Test (UUT)
    --    Conecta os sinais do testbench �s portas do processador
    UUT : toplevel
        port map (
            clk => tb_clk,
            rst => tb_rst
        );

    -- 5. Clock generation process
    --    Este processo gera um sinal de clock cont�nuo
    clock_gen_proc : process
    begin
        loop
            tb_clk <= '0';
            wait for CLOCK_PERIOD / 2;
            tb_clk <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process clock_gen_proc;

    -- 6. Test stimulus process
    --    Este processo controla o reset e o tempo de simula��o
    stimulus_proc : process
    begin
        report "--- Iniciando Simula��o do Processador ---";
        
        -- Mant�m o processador em reset por 5 ciclos de clock
        tb_rst <= '1';
        report "Aplicando reset...";
        wait for CLOCK_PERIOD * 5;

        -- Libera o reset. O processador come�ar� a rodar (buscar instru��o 0)
        tb_rst <= '0';
        report "Reset liberado. Processador est� rodando o programa da mem�ria...";
        
        -- Deixa a simula��o rodar por um tempo
        -- Mude '200' para o n�mero de ciclos que seu programa precisa
        wait for CLOCK_PERIOD * 200; 

        report "Simula��o terminada. Verifique os resultados na waveform.";
        
        -- Para a simula��o
        wait; 

    end process stimulus_proc;

end Behavioral;