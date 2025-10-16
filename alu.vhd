-- alu.vhd
-- typo mistake
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        a       : in  STD_LOGIC_VECTOR(31 downto 0);
        b       : in  STD_LOGIC_VECTOR(31 downto 0);
        alu_op  : in  STD_LOGIC_VECTOR(3 downto 0);
        result  : out STD_LOGIC_VECTOR(31 downto 0);
        zero    : out std_logic
    );
end alu;

architecture Behavioral of alu is
    signal result_signed : signed(31 downto 0);
    signal result_vec    : std_logic_vector(31 downto 0);
begin

    process(a, b, alu_op)
    begin
        -- default
        result_signed <= (others => '0');
        result_vec    <= (others => '0');

        case alu_op is
            when "0000" =>  -- add
                result_signed <= signed(a) + signed(b);
                result_vec <= std_logic_vector(result_signed);

            when "0001" =>  -- bitwise AND
                result_vec <= a and b;

            when "0010" =>  -- subtract
                result_signed <= signed(a) - signed(b);
                result_vec <= std_logic_vector(result_signed);

            when others =>
                result_vec <= (others => '0');
        end case;
    end process;

    result <= result_vec;

    -- zero flag
    zero <= '1' when result_vec = (others => '0') else '0';

end Behavioral;
