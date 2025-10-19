library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        opcode  : in  std_logic_vector(3 downto 0); -- Sua entrada de 4 bits
        
        -- Write Enables
        pc_we       : out std_logic;
        reg_inst_we : out std_logic;
        reg_a_we    : out std_logic;
        reg_b_we    : out std_logic;
        reg_data_we : out std_logic;
        ula_out_we  : out std_logic;
        regfile_we  : out std_logic;
        mem_we      : out std_logic;

        -- Seletores de MUX
        ALUSrcB   : out std_logic;
        MemToReg  : out std_logic;
        alu_sel   : out std_logic_vector(2 downto 0);
        
        -- Sinais de Desvio
        is_jump   : out std_logic;
        is_branch : out std_logic
        -- REMOVIDO: flag_sel (não é usado por nenhum componente seu)
    );
end entity;

architecture fsm of control_unit is
    type state_t is (S_FETCH, S_DECODE, S_EXEC_R, S_EXEC_I, S_EXEC_J, S_MEM, S_WB);
    signal state, next_state : state_t;

begin
    ----------------------------------------------------------------
    -- Processo 1: Registrador de Estado (Correto)
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
    -- Processo 2: Lógica Combinacional (CORRIGIDO)
    ----------------------------------------------------------------
    process(state, opcode)
    begin
        -- 1. Valores Padrão
        pc_we       <= '0';
        reg_inst_we <= '0';
        reg_a_we    <= '0';
        reg_b_we    <= '0';
        reg_data_we <= '0';
        ula_out_we  <= '0';
        regfile_we  <= '0';
        mem_we      <= '0';
        ALUSrcB     <= '0';
        MemToReg    <= '0';
        alu_sel     <= "000";
        is_jump     <= '0';
        is_branch   <= '0';
        next_state  <= S_FETCH; -- Padrão

        -- 2. Lógica de Estados (FSM)
        case state is
            ----------------------------------------------------------------
            -- CICLO 1: S_FETCH (Correto)
            when S_FETCH =>
                reg_inst_we <= '1';
                pc_we       <= '1';
                next_state  <= S_DECODE;

            ----------------------------------------------------------------
            -- CICLO 2: S_DECODE (CORRIGIDO com sua lista)
            when S_DECODE =>
                reg_a_we <= '1';
                reg_b_we <= '1';
                
                case opcode is
                    when "0000" | "0001" | "0010" => -- ADD, AND, SUB
                        next_state <= S_EXEC_R;
                    when "0100" | "0101" =>         -- LW, SW
                        next_state <= S_EXEC_I;
                    when "0110" | "1000" =>         -- BEQ, JUMP
                        next_state <= S_EXEC_J;
                    when others =>
                        next_state <= S_FETCH; -- Instrução inválida
                end case;

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_R (Correto)
            when S_EXEC_R =>
                ula_out_we <= '1';
                ALUSrcB    <= '0';
                alu_sel    <= opcode(2 downto 0); -- ADD(000), AND(001), SUB(010)
                next_state <= S_WB;

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_I (Correto)
            when S_EXEC_I =>
                ula_out_we <= '1';
                ALUSrcB    <= '1'; -- Mux da ULA seleciona o Imediato
                alu_sel    <= "000"; -- ULA deve somar (para LW/SW)
                next_state <= S_MEM; 

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_J (CORRIGIDO com sua lista)
            when S_EXEC_J =>
                pc_we <= '1'; -- Habilita escrita no PC
                
                case opcode is
                    when "1000" => -- JUMP
                        is_jump <= '1';
                    when "0110" => -- BEQ
                        is_branch <= '1';
                    when others =>
                        null;
                end case;
                next_state <= S_FETCH; -- Desvios terminam aqui

            ----------------------------------------------------------------
            -- CICLO 4: S_MEM (Correto)
            when S_MEM =>
                if opcode = "0101" then -- SW
                    mem_we     <= '1';
                    next_state <= S_FETCH; -- Termina
                else -- LW ("0100")
                    reg_data_we <= '1';
                    next_state  <= S_WB;
                end if;

            ----------------------------------------------------------------
            -- CICLO 5: S_WB (Correto)
            when S_WB =>
                regfile_we <= '1';
                
                if opcode = "0100" then -- LW
                    MemToReg <= '1'; -- Dado vem da Memória
                else -- Tipo-R
                    MemToReg <= '0'; -- Dado vem da ULA
                end if;
                
                next_state <= S_FETCH;

        end case;
    end process;
end architecture;