library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        -- entrada
        opcode  : in  std_logic_vector(3 downto 0); -- CORRETO (baseado na sua imagem)
        
        -- SINAIS DE CONTROLE (SA�DAS) - CORRIGIDOS E COMPLETOS
        
        -- Write Enables (WE) para os Registradores
        pc_we       : out std_logic; -- (NOVO) Habilita escrita no PC
        reg_inst_we : out std_logic; -- (NOVO) Habilita escrita no Reg_Inst
        reg_a_we    : out std_logic; -- we_A: Habilita escrita no Reg_A (temp)
        reg_b_we    : out std_logic; -- we_B: Habilita escrita no Reg_B (temp)
        reg_data_we : out std_logic; -- (NOVO) Habilita escrita no Reg_Data
        ula_out_we  : out std_logic; -- we_ULAout: Habilita escrita no ULA_out (temp)
        regfile_we  : out std_logic; -- Habilita escrita no Banco de Registradores
        mem_we      : out std_logic; -- Habilita escrita na Mem�ria (para Store)

        -- Seletores de MUX
        ALUSrcB   : out std_logic; -- (NOVO) 0=Reg_B, 1=Imediato (para Tipo-I)
        MemToReg  : out std_logic; -- (NOVO) 0=ULA_out, 1=Reg_Data (para LW)
        alu_sel   : out std_logic_vector(2 downto 0);
        
        -- Sinais de Desvio (Mantidos do seu original)
        is_jump   : out std_logic;
        is_branch : out std_logic;
        flag_sel  : out std_logic_vector(1 downto 0)
    );
end entity;

architecture fsm of control_unit is
    type state_t is (S_FETCH, S_DECODE, S_EXEC_R, S_EXEC_I, S_EXEC_J, S_MEM, S_WB);
    signal state, next_state : state_t;

begin
    ----------------------------------------------------------------
    -- Sequ�ncia de estados (Registrador de Estado)
    ----------------------------------------------------------------
    -- Este processo est� CORRETO. N�o mude.
    process(clk, rst)
    begin
        if rst = '1' then
            state <= S_FETCH;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    ----------------------------------------------------------------
    -- L�gica da UC (L�gica Combinacional)
    -- ESTA � A PARTE PRINCIPAL QUE FOI CORRIGIDA
    ----------------------------------------------------------------
    process(state, opcode)
    begin
        -- 1. Valores Padr�o (Define o que acontece se nada for ativado)
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
        flag_sel    <= "00";
        
        next_state  <= S_FETCH; -- Padr�o � voltar ao in�cio

        -- 2. L�gica de Estados (FSM)
        case state is
            ----------------------------------------------------------------
            -- CICLO 1: Buscar instru��o
            when S_FETCH =>
                -- A��o: Salvar instru��o no Reg_Inst e calcular PC+4
                reg_inst_we <= '1'; -- Salva a instru��o que vem da mem�ria
                pc_we       <= '1'; -- Salva o novo valor do PC (que vem do Mux_PC)
                next_state  <= S_DECODE;

            ----------------------------------------------------------------
            -- CICLO 2: Decodificar e buscar operandos
            when S_DECODE =>
                -- A��o: Ler do Banco de Reg. e salvar em Reg_A e Reg_B
                reg_a_we <= '1'; -- Salva a sa�da 'DADO' (reg1) do Regs no Reg_A
                reg_b_we <= '1'; -- Salva a sa�da 'DADO' (reg2) do Regs no Reg_B
                
                -- Decodifica o opcode (l�gica original) para decidir pr�ximo estado
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
            -- CICLO 3: Execu��o (Tipo R)
            when S_EXEC_R =>
                -- A��o: ULA opera com Reg_A e Reg_B. Salva em ULA_out.
                ula_out_we <= '1';
                ALUSrcB    <= '0'; -- Fonte B � Reg_B
                alu_sel    <= opcode(2 downto 0); -- (L�gica original)
                next_state <= S_WB; -- Pula S_MEM e vai para Write-Back

            ----------------------------------------------------------------
            -- CICLO 3: Execu��o (Tipo I - C�lculo de Endere�o)
            when S_EXEC_I =>
                -- A��o: ULA calcula endere�o (Reg_A + Imediato). Salva em ULA_out.
                ula_out_we <= '1';
                ALUSrcB    <= '1'; -- Fonte B � o Imediato (vindo do Reg_Inst)
                alu_sel    <= "000"; -- (L�gica original - ADD)
                next_state <= S_MEM; -- Pr�ximo passo � acessar a mem�ria

            ----------------------------------------------------------------
            -- CICLO 3: Execu��o (Jump/Branch)
            when S_EXEC_J =>
                -- A��o: Atualizar o PC se a condi��o for verdadeira.
                pc_we <= '1'; -- Habilita a escrita no PC
                
                -- (L�gica original para selecionar a fonte do Mux_PC)
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
                next_state <= S_FETCH; -- Desvios terminam em 1 ciclo

            ----------------------------------------------------------------
            -- CICLO 4: Acesso � Mem�ria (para LOAD/STORE)
            when S_MEM =>
                if opcode = "0101" then
                    -- STORE: Escreve na mem�ria
                    mem_we     <= '1';
                    next_state <= S_FETCH; -- Termina
                else
                    -- LOAD: L� da mem�ria e salva em Reg_Data
                    reg_data_we <= '1';
                    next_state  <= S_WB; -- Pr�ximo passo � Write-Back
                end if;

            ----------------------------------------------------------------
            -- CICLO 5: Write-Back (para Tipo-R e LOAD)
            when S_WB =>
                -- A��o: Escreve o resultado no Banco de Registradores
                regfile_we <= '1';
                
                if opcode = "0100" then
                    -- Se for LOAD ("0100")
                    MemToReg <= '1'; -- Seleciona o dado vindo da mem�ria (Reg_Data)
                else
                    -- Se for Tipo-R ("0000" a "0011")
                    MemToReg <= '0'; -- Seleciona o dado vindo da ULA (ULA_out)
                end if;
                
                next_state <= S_FETCH; -- Termina

        end case;
    end process;
end architecture;