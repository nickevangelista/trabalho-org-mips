library ieee;
use ieee.std_logic_1164.all;

entity pc is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        d   : in  std_logic_vector(15 downto 0);
        q   : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of pc is
    signal reg : std_logic_vector(15 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            else
                reg <= d;
            end if;
        end if;
    end process;

    q <= reg;
end architecture;