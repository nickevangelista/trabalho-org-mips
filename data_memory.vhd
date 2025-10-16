library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_memory is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;

        addr  : in  std_logic_vector(9 downto 0);   -- 1024 palavras
        wdata : in  std_logic_vector(15 downto 0);  -- dado a escrever
        rdata : out std_logic_vector(15 downto 0);  -- dado lido

        we    : in std_logic  -- habilita escrita
    );
end entity;

architecture rtl of data_memory is
    type ram_t is array (0 to 1023) of std_logic_vector(15 downto 0);
    signal mem : ram_t := (others => (others => '0'));
    signal rdata_reg : std_logic_vector(15 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mem <= (others => (others => '0'));
                rdata_reg <= (others => '0');
            else
                if we = '1' then
                    mem(to_integer(unsigned(addr))) <= wdata;
                end if;
                -- leitura s?ncrona
                rdata_reg <= mem(to_integer(unsigned(addr)));
            end if;
        end if;
    end process;

    rdata <= rdata_reg;
end architecture;