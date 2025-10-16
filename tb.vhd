library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Useful if you want to display integer values for debugging

entity Calculadora_tb is
end Calculadora_tb;

architecture Behavioral of Calculadora_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component Calculadora
        port (
            clock, start, reset : in std_logic;
            a, b, c             : in std_logic_vector(15 downto 0);
            r                   : out std_logic_vector(15 downto 0)
        );
    end component;

    -- Signals for the testbench
    signal tb_clock : std_logic := '0'; -- Initialize clock to '0'
    signal tb_start : std_logic := '0';
    signal tb_reset : std_logic := '1'; -- Start in reset state
    signal tb_a     : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_b     : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_c     : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_r     : std_logic_vector(15 downto 0);

    -- Clock period definition
    constant CLOCK_PERIOD : time := 10 ns; -- 10 nanoseconds clock period

begin

    -- Instantiate the Unit Under Test (UUT)
    UUT : Calculadora
        port map (
            clock => tb_clock,
            start => tb_start,
            reset => tb_reset,
            a     => tb_a,
            b     => tb_b,
            c     => tb_c,
            r     => tb_r
        );

    -- Clock generation process
    clock_gen_proc : process
    begin
        loop
            tb_clock <= '0';
            wait for CLOCK_PERIOD / 2;
            tb_clock <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process clock_gen_proc;

    -- Test stimulus process
    stimulus_proc : process
    begin
        report "--- Simulation Start ---";
        
        -- FAZ A = 2 B = 2 C = 4, Resultado esperado: -28
        tb_reset <= '1';
        report "Applying reset";
        wait for CLOCK_PERIOD * 2; -- Hold reset for a few clock cycles

        tb_reset <= '0';
        report "Releasing reset, setting inputs A=2, B=2, C=4";
        tb_a     <= std_logic_vector(to_signed(2, 16)); -- A = 2
        tb_b     <= std_logic_vector(to_signed(2, 16)); -- B = 2
        tb_c     <= std_logic_vector(to_signed(4, 16)); -- C = 4
        wait for CLOCK_PERIOD*4; -- Give some time for inputs to propagate

        report "Asserting start signal...";
        tb_start <= '1';
        wait for CLOCK_PERIOD; 

        report "Deasserting start signal...";
        tb_start <= '0';

        report "Waiting for calculation to complete...";
        wait for CLOCK_PERIOD * 10; 

        -- FAZ A = 4 B = 4 C = 2, Resultado esperado: 1/2 ou 1 no caso
        tb_reset <= '1';
        report "Applying reset";
        wait for CLOCK_PERIOD * 2; -- Hold reset for a few clock cycles

        tb_reset <= '0';
        report "Releasing reset, setting inputs A=2, B=2, C=4";
        tb_a     <= std_logic_vector(to_signed(4, 16)); -- A = 4
        tb_b     <= std_logic_vector(to_signed(4, 16)); -- B = 4
        tb_c     <= std_logic_vector(to_signed(2, 16)); -- C = 2
        wait for CLOCK_PERIOD*4; -- Give some time for inputs to propagate

        report "Asserting start signal...";
        tb_start <= '1';
        wait for CLOCK_PERIOD; 

        report "Deasserting start signal...";
        tb_start <= '0';

        report "Waiting for calculation to complete...";
        wait for CLOCK_PERIOD * 10; 
        
        wait; -- Wait forever to end the simulation

    end process stimulus_proc;

end Behavioral;**
**