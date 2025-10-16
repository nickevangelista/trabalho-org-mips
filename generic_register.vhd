library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temp_reg is
    generic (
        N : integer := 16  -- largura do registrador
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        we  : in  std_logic;  -- habilita escrita
        d   : in  std_logic_vector(N-1 downto 0);
        q   : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture rtl of temp_reg is
    signal reg : std_logic_vector(N-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            elsif we = '1' then
                reg <= d;
            end if;
        end if;
    end process;

    q <= reg;
end architecture;