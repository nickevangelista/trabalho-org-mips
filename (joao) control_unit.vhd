library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;

        -- entrada
        opcode : in std_logic_vector(3 downto 0);

        -- sinais de controle (sa?das)
        we_A, we_B, we_C, we_ULAout : out std_logic;
        we_regfile : out std_logic;
        we_mem     : out std_logic;

        alu_sel    : out std_logic_vector(2 downto 0);
        is_jump    : out std_logic;
        is_branch  : out std_logic;
        flag_sel   : out std_logic_vector(1 downto 0)
    );
end entity;

architecture fsm of control_unit is
    type state_t is (S_FETCH, S_DECODE, S_EXEC_R, S_EXEC_I, S_EXEC_J, S_MEM, S_WB);
    signal state, next_state : state_t;

begin
    ----------------------------------------------------------------
    -- Sequ?ncia de estados
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            state <= S_FETCH;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    ----------------------------------------------------------------
    -- L?gica da UC
    ----------------------------------------------------------------
    process(state, opcode)
    begin
        -- valores padr?o
        we_A      <= '0';
        we_B      <= '0';
        we_C      <= '0';
        we_ULAout <= '0';
        we_regfile <= '0';
        we_mem     <= '0';
        alu_sel    <= "000";
        is_jump    <= '0';
        is_branch  <= '0';
        flag_sel   <= "00";
        next_state <= S_FETCH;

        case state is
            ----------------------------------------------------------------
            when S_FETCH =>
                -- pr?xima instru??o ser? carregada
                next_state <= S_DECODE;

            ----------------------------------------------------------------
            when S_DECODE =>
                case opcode is
                    when "0000" | "0001" | "0010" | "0011" =>
                        -- tipo R (ADD, SUB, MUL, DIV)
                        next_state <= S_EXEC_R;
                    when "0100" | "0101" =>
                        -- LOAD, STORE
                        next_state <= S_EXEC_I;
                    when "0110" | "0111" | "1000" | "1001" =>
                        -- JUMP, JEQ, JBG, JLR
                        next_state <= S_EXEC_J;
                    when others =>
                        next_state <= S_FETCH;
                end case;

            ----------------------------------------------------------------
            when S_EXEC_R =>
                -- tipo R ? A e B j? carregados, manda para ULA
                we_A <= '1';
                we_B <= '1';
                we_ULAout <= '1';
                alu_sel <= opcode(2 downto 0); -- usa opcode como seletor da ULA
                next_state <= S_WB;

            ----------------------------------------------------------------
            when S_EXEC_I =>
                -- LOAD/STORE ? calcula endere?o
                we_A <= '1';
                we_B <= '1';
                we_ULAout <= '1';
                alu_sel <= "000"; -- ADD
                next_state <= S_MEM;

            ----------------------------------------------------------------
            when S_EXEC_J =>
                case opcode is
                    when "0110" => -- JMP
                        is_jump <= '1';
                    when "0111" => -- JEQ
                        is_branch <= '1';
                        flag_sel  <= "00"; -- usa flag zero
                    when "1000" => -- JBG
                        is_branch <= '1';
                        flag_sel  <= "01"; -- usa flag greater
                    when "1001" => -- JLR
                        is_branch <= '1';
                        flag_sel  <= "10"; -- usa flag less
                    when others =>
                        null;
                end case;
                next_state <= S_FETCH;

            ----------------------------------------------------------------
            when S_MEM =>
                if opcode = "0101" then
                    -- STORE
                    we_mem <= '1';
                else
                    -- LOAD ? pr?ximo ? WB
                    next_state <= S_WB;
                end if;

            ----------------------------------------------------------------
            when S_WB =>
                -- escreve no banco de registradores
                we_regfile <= '1';
                next_state <= S_FETCH;

        end case;
    end process;
end architecture;