library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;

        -- endere?os
        rs_addr : in std_logic_vector(2 downto 0);  -- registrador fonte 1
        rt_addr : in std_logic_vector(2 downto 0);  -- registrador fonte 2
        rd_addr : in std_logic_vector(2 downto 0);  -- registrador destino (escrita)

        -- dados
        rd_data_in  : in  std_logic_vector(15 downto 0); -- dado para escrever
        rs_data_out : out std_logic_vector(15 downto 0); -- valor lido de rs
        rt_data_out : out std_logic_vector(15 downto 0); -- valor lido de rt

        -- controle
        we : in std_logic  -- habilita escrita no registrador destino
    );
end entity;

architecture rtl of reg_file is
    type reg_array_t is array (0 to 7) of std_logic_vector(15 downto 0);
    signal regs : reg_array_t := (others => (others => '0'));
begin
    -- escrita s?ncrona
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));
            elsif we = '1' then
                regs(to_integer(unsigned(rd_addr))) <= rd_data_in;
            end if;
        end if;
    end process;

    -- leituras combinacionais
    rs_data_out <= regs(to_integer(unsigned(rs_addr)));
    rt_data_out <= regs(to_integer(unsigned(rt_addr)));
end architecture;