library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        -- entrada
        opcode  : in  std_logic_vector(3 downto 0); -- CORRETO (baseado na sua imagem)
        
        -- SINAIS DE CONTROLE (SAÍDAS) - CORRIGIDOS E COMPLETOS
        
        -- Write Enables (WE) para os Registradores
        pc_we       : out std_logic; -- (NOVO) Habilita escrita no PC
        reg_inst_we : out std_logic; -- (NOVO) Habilita escrita no Reg_Inst
        reg_a_we    : out std_logic; -- we_A: Habilita escrita no Reg_A (temp)
        reg_b_we    : out std_logic; -- we_B: Habilita escrita no Reg_B (temp)
        reg_data_we : out std_logic; -- (NOVO) Habilita escrita no Reg_Data
        ula_out_we  : out std_logic; -- we_ULAout: Habilita escrita no ULA_out (temp)
        regfile_we  : out std_logic; -- Habilita escrita no Banco de Registradores
        mem_we      : out std_logic; -- Habilita escrita na Memória (para Store)

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
    -- Sequência de estados (Registrador de Estado)
    ----------------------------------------------------------------
    -- Este processo está CORRETO. Não mude.
    process(clk, rst)
    begin
        if rst = '1' then
            state <= S_FETCH;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Lógica da UC (Lógica Combinacional)
    -- ESTA É A PARTE PRINCIPAL QUE FOI CORRIGIDA
    ----------------------------------------------------------------
    process(state, opcode)
    begin
        -- 1. Valores Padrão (Define o que acontece se nada for ativado)
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
        
        next_state  <= S_FETCH; -- Padrão é voltar ao início

        -- 2. Lógica de Estados (FSM)
        case state is
            ----------------------------------------------------------------
            -- CICLO 1: Buscar instrução
            when S_FETCH =>
                -- Ação: Salvar instrução no Reg_Inst e calcular PC+4
                reg_inst_we <= '1'; -- Salva a instrução que vem da memória
                pc_we       <= '1'; -- Salva o novo valor do PC (que vem do Mux_PC)
                next_state  <= S_DECODE;

            ----------------------------------------------------------------
            -- CICLO 2: Decodificar e buscar operandos
            when S_DECODE =>
                -- Ação: Ler do Banco de Reg. e salvar em Reg_A e Reg_B
                reg_a_we <= '1'; -- Salva a saída 'DADO' (reg1) do Regs no Reg_A
                reg_b_we <= '1'; -- Salva a saída 'DADO' (reg2) do Regs no Reg_B
                
                -- Decodifica o opcode (lógica original) para decidir próximo estado
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
            -- CICLO 3: Execução (Tipo R)
            when S_EXEC_R =>
                -- Ação: ULA opera com Reg_A e Reg_B. Salva em ULA_out.
                ula_out_we <= '1';
                ALUSrcB    <= '0'; -- Fonte B é Reg_B
                alu_sel    <= opcode(2 downto 0); -- (Lógica original)
                next_state <= S_WB; -- Pula S_MEM e vai para Write-Back

            ----------------------------------------------------------------
            -- CICLO 3: Execução (Tipo I - Cálculo de Endereço)
            when S_EXEC_I =>
                -- Ação: ULA calcula endereço (Reg_A + Imediato). Salva em ULA_out.
                ula_out_we <= '1';
                ALUSrcB    <= '1'; -- Fonte B é o Imediato (vindo do Reg_Inst)
                alu_sel    <= "000"; -- (Lógica original - ADD)
                next_state <= S_MEM; -- Próximo passo é acessar a memória

            ----------------------------------------------------------------
            -- CICLO 3: Execução (Jump/Branch)
            when S_EXEC_J =>
                -- Ação: Atualizar o PC se a condição for verdadeira.
                pc_we <= '1'; -- Habilita a escrita no PC
                
                -- (Lógica original para selecionar a fonte do Mux_PC)
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
            -- CICLO 4: Acesso à Memória (para LOAD/STORE)
            when S_MEM =>
                if opcode = "0101" then
                    -- STORE: Escreve na memória
                    mem_we     <= '1';
                    next_state <= S_FETCH; -- Termina
                else
                    -- LOAD: Lê da memória e salva em Reg_Data
                    reg_data_we <= '1';
                    next_state  <= S_WB; -- Próximo passo é Write-Back
                end if;

            ----------------------------------------------------------------
            -- CICLO 5: Write-Back (para Tipo-R e LOAD)
            when S_WB =>
                -- Ação: Escreve o resultado no Banco de Registradores
                regfile_we <= '1';
                
                if opcode = "0100" then
                    -- Se for LOAD ("0100")
                    MemToReg <= '1'; -- Seleciona o dado vindo da memória (Reg_Data)
                else
                    -- Se for Tipo-R ("0000" a "0011")
                    MemToReg <= '0'; -- Seleciona o dado vindo da ULA (ULA_out)
                end if;
                
                next_state <= S_FETCH; -- Termina

        end case;
    end process;
end architecture;