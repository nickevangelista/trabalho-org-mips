library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ula is
    Port (
        a       : in  STD_LOGIC_VECTOR(31 downto 0);
        b       : in  STD_LOGIC_VECTOR(31 downto 0);
        ula_op  : in  STD_LOGIC_VECTOR(1 downto 0); -- add (00), sub (01), and (10)
        result  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end ula;

architecture Behavioral of ula is
begin
    process(a, b, ula_op)
        variable res : signed(31 downto 0);
    begin
        case ula_op is
            when "00" =>   -- ADD
                res := signed(a) + signed(b);

            when "01" =>   -- SUB
                res := signed(a) - signed(b);

            when "10" =>   -- AND
                res := signed(a and b);

            when others =>
                res := (others => '0');
        end case;

        result <= std_logic_vector(res);
    end process;
end Behavioral;