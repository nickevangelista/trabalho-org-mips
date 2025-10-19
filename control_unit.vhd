library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        opcode  : in  std_logic_vector(3 downto 0);
        
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
    );
end entity;

architecture fsm of control_unit is
    -- ADICIONADO NOVO ESTADO S_EXEC_B (para Branch)
    type state_t is (S_FETCH, S_DECODE, S_EXEC_R, S_EXEC_I, S_EXEC_B, S_EXEC_J, S_MEM, S_WB);
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
    -- Processo 2: L�gica Combinacional (CORRIGIDO)
    ----------------------------------------------------------------
    process(state, opcode)
    begin
        -- 1. Valores Padr�o
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
        next_state  <= S_FETCH;

        -- 2. L�gica de Estados (FSM)
        case state is
            ----------------------------------------------------------------
            -- CICLO 1: S_FETCH (Correto)
            when S_FETCH =>
                reg_inst_we <= '1';
                pc_we       <= '1';
                next_state  <= S_DECODE;

            ----------------------------------------------------------------
            -- CICLO 2: S_DECODE (CORRIGIDO para BEQ)
            when S_DECODE =>
                reg_a_we <= '1'; -- Salva rs
                reg_b_we <= '1'; -- Salva rt
                
                case opcode is
                    when "0000" | "0001" | "0010" => -- ADD, AND, SUB
                        next_state <= S_EXEC_R;
                    when "0100" | "0101" =>         -- LW, SW
                        next_state <= S_EXEC_I;
                    when "0110" =>                  -- BEQ
                        next_state <= S_EXEC_B;     -- <-- CORRIGIDO
                    when "1000" =>                  -- JUMP
                        next_state <= S_EXEC_J;     -- <-- CORRIGIDO
                    when others =>
                        next_state <= S_FETCH;
                end case;

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_R (Tipo-R: ADD, AND, SUB)
            when S_EXEC_R =>
                ula_out_we <= '1';
                ALUSrcB    <= '0';
                alu_sel    <= opcode(2 downto 0);
                next_state <= S_WB;

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_I (Tipo-I: LW, SW)
            when S_EXEC_I =>
                -- Calcula endere�o (R_base + Imediato)
                ula_out_we <= '1';
                ALUSrcB    <= '1'; -- Seleciona Imediato
                alu_sel    <= "000"; -- ULA faz SOMA
                next_state <= S_MEM; 

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_B (Tipo-I: BEQ) -- NOVO ESTADO
            when S_EXEC_B =>
                -- A��o:
                -- 1. O subtrator_beq (fora da UC) compara Reg_A e Reg_B (OK)
                -- 2. A ULA precisa calcular o endere�o de desvio (PC + Imediato)
                --    (ATEN��O: Isso exige um MUX na entrada A da ULA no seu toplevel)
                
                -- Assumindo que a ULA calcula o endere�o de branch:
                ula_out_we <= '1'; -- Salva o endere�o de branch (PC + Imediato)
                ALUSrcB    <= '1'; -- ULA B = Imediato
                alu_sel    <= "000"; -- ULA faz SOMA
                -- (Voc� precisa de um Mux para ULA A = PC)
                
                -- Ativa os sinais de branch para o Mux_PC
                is_branch  <= '1';
                pc_we      <= '1';
                next_state <= S_FETCH; -- Termina o ciclo

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_J (Tipo-J: JUMP) -- CORRIGIDO
            when S_EXEC_J =>
                -- A��o: A ULA calcula o endere�o de JUMP
                
                -- Assumindo que o endere�o de JUMP � o Imediato (absoluto)
                -- e a ULA precisa passar o Imediato para ULA_out
                ula_out_we <= '1';
                ALUSrcB    <= '1';
                -- (Precisaria de uma opera��o "Bypass B" na ULA, ex: "111")
                -- Vamos usar a SOMA com Zero (Reg_A = 0) se n�o puder
                alu_sel    <= "000"; -- (Assumindo que Reg_A est� zerado ou Mux A existe)
                
                -- Ativa os sinais de jump para o Mux_PC
                is_jump    <= '1';
                pc_we      <= '1';
                next_state <= S_FETCH; -- Termina o ciclo

            ----------------------------------------------------------------
            -- CICLO 4: S_MEM (LW/SW)
            when S_MEM =>
                if opcode = "0101" then -- SW
                    mem_we     <= '1';
                    next_state <= S_FETCH;
                else -- LW ("0100")
                    reg_data_we <= '1';
                    next_state  <= S_WB;
                end if;

            ----------------------------------------------------------------
            -- CICLO 5: S_WB (Tipo-R / LW)
            when S_WB =>
                regfile_we <= '1';
                
                if opcode = "0100" then -- LW
                    MemToReg <= '1'; -- Dado vem da Mem�ria
                else -- Tipo-R
                    MemToReg <= '0'; -- Dado vem da ULA
                end if;
                
                next_state <= S_FETCH;

        end case;
    end process;
end architecture;