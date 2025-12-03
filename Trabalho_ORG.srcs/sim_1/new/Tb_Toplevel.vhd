library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_TopLevel is
end TB_TopLevel;

architecture sim of TB_TopLevel is

    -- Clock e Reset
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- Instância do TopLevel
    component TopLevel
        port(
            clk   : in std_logic;
            reset : in std_logic
        );
    end component;

begin

    --------------------------------------------------------------------
    -- CLOCK: 10 ns
    --------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    UUT : TopLevel
        port map (
            clk   => clk,
            reset => reset
        );

    --------------------------------------------------------------------
    -- ESTÍMULOS
    --------------------------------------------------------------------
    process
    begin
        -- RESET INICIAL
        reset <= '1';
        wait for 30 ns;
        reset <= '0';

        -- Deixa a unidade de controle controlar tudo
        -- Durante este tempo:
        --  • LW R1 ← MEM[512]
        --  • LW R2 ← MEM[513]
        --  • ADD R3 = R1 + R2
        --  • SW R3 → MEM[520]
        -- Acontecem automaticamente
        wait for 2000 ns;

        wait;
    end process;

end sim;