library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ULA is
    Port (
        A       : in  STD_LOGIC_VECTOR(31 downto 0);
        B       : in  STD_LOGIC_VECTOR(31 downto 0);
        Op      : in  STD_LOGIC_VECTOR(3 downto 0);
        ULA_Out : out STD_LOGIC_VECTOR(31 downto 0)
    );
end ULA;

architecture Behavioral of ULA is
    signal Reg_A, Reg_B, Result : signed(31 downto 0);
begin
    Reg_A <= signed(A);
    Reg_B <= signed(B);

    process(Reg_A, Reg_B, Op)
    begin
        case OP is
            when "0000" =>  
                Result <= Reg_A + Reg_B;

            when "0001" =>  
                Result <= Reg_A and Reg_B;

            when "0010" =>  
                Result <= Reg_A - Reg_B;

            when others =>
                Result <= (others => '0');
        end case;
    end process;

    ULA_Out <= std_logic_vector(Result);
end Behavioral;