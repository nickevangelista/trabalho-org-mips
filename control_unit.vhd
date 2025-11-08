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
        is_branch : out std_logic;

        -- Sinal extra esperado pelo toplevel (não usado em outros módulos por enquanto)
        flag_sel  : out std_logic_vector(1 downto 0)
    );
end entity;

architecture fsm of control_unit is
    -- ADICIONADO NOVO ESTADO S_EXEC_B (para Branch)
    type state_t is (S_FETCH, S_DECODE, S_EXEC_R, S_EXEC_I, S_EXEC_B, S_EXEC_J, S_MEM, S_WB);
    signal state, next_state : state_t;

begin
    ----------------------------------------------------------------
    -- Processo 1: Registrador de Estado
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
    -- Processo 2: Lógica Combinacional (sinais de controle)
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
        flag_sel    <= "00";   -- default (adicionado para compatibilidade com toplevel)
        next_state  <= S_FETCH;

        -- 2. Lógica de Estados (FSM)
        case state is
            ----------------------------------------------------------------
            -- CICLO 1: S_FETCH
            when S_FETCH =>
                reg_inst_we <= '1';
                pc_we       <= '1';
                next_state  <= S_DECODE;

            ----------------------------------------------------------------
            -- CICLO 2: S_DECODE
            when S_DECODE =>
                reg_a_we <= '1'; -- Salva rs
                reg_b_we <= '1'; -- Salva rt
                
                case opcode is
                    when "0000" | "0001" | "0010" => -- ADD, AND, SUB (R-type)
                        next_state <= S_EXEC_R;
                    when "0100" | "0101" =>         -- LW, SW (I-type)
                        next_state <= S_EXEC_I;
                    when "0110" =>                  -- BEQ
                        next_state <= S_EXEC_B;
                    when "1000" =>                  -- JUMP
                        next_state <= S_EXEC_J;
                    when others =>
                        next_state <= S_FETCH;
                end case;

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_R (Tipo-R: ADD, AND, SUB)
            when S_EXEC_R =>
                ula_out_we <= '1';
                ALUSrcB    <= '0'; -- operando B vem do reg B
                alu_sel    <= opcode(2 downto 0); -- usa os 3 LSBs do opcode para selecionar operação
                next_state <= S_WB;

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_I (Tipo-I: LW, SW) - calcula endereço
            when S_EXEC_I =>
                ula_out_we <= '1';
                ALUSrcB    <= '1'; -- Seleciona Imediato
                alu_sel    <= "000"; -- ULA faz SOMA (base + immediate)
                next_state <= S_MEM; 

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_B (BEQ)
            when S_EXEC_B =>
                -- A ULA (no seu toplevel) calcula o endereço de branch (PC + Imediato)
                ula_out_we <= '1'; -- salva endereço de branch na saída da ULA
                ALUSrcB    <= '1'; -- ULA B = Imediato (PC deve ser conectado como A pelo top)
                alu_sel    <= "000"; -- soma (PC + offset)
                
                -- ativa sinais de branch/jump e atualiza PC
                is_branch  <= '1';
                pc_we      <= '1';
                next_state <= S_FETCH; -- ciclo termina aqui (assumindo multiplexagem no PC)

            ----------------------------------------------------------------
            -- CICLO 3: S_EXEC_J (JUMP)
            when S_EXEC_J =>
                -- Tratamos salto similarmente: ULA_out recebe target (ou bypass)
                ula_out_we <= '1';
                ALUSrcB    <= '1'; -- acomodar encaminhamento do imediato como target
                alu_sel    <= "000"; -- soma com zero / ou outra lógica dependendo do toplevel
                
                is_jump    <= '1';
                pc_we      <= '1';
                next_state <= S_FETCH;

            ----------------------------------------------------------------
            -- CICLO 4: S_MEM (LW / SW)
            when S_MEM =>
                if opcode = "0101" then -- SW
                    mem_we     <= '1';
                    next_state <= S_FETCH;
                else -- LW ("0100")
                    reg_data_we <= '1';
                    next_state  <= S_WB;
                end if;

            ----------------------------------------------------------------
            -- CICLO 5: S_WB (Write Back - Tipo-R / LW)
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