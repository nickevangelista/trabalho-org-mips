library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Para converter inteiros em vetores

entity tb_datapath_soma is
end tb_datapath_soma;

architecture behavior of tb_datapath_soma is

    component data_path
    port(
        clk           : in std_logic;
        reset         : in std_logic;
        
        -- Sinais de Controle (Que viriam da Control Unit)
        reg_dst       : in std_logic;
        alu_src       : in std_logic;
        mem_to_reg    : in std_logic;
        reg_write     : in std_logic;
        mem_read      : in std_logic;
        mem_write     : in std_logic;
        alu_control   : in std_logic_vector(2 downto 0); -- Assumindo 3 bits
        
        -- Entrada da Instrução (Simulando a Memória de Instrução)
        instruction   : in std_logic_vector(31 downto 0);
        
        -- Saída para verificação (Resultado da ALU)
        alu_result    : out std_logic_vector(31 downto 0)
    );
    end component;

    -- 2. Sinais internos para ligar no componente
    signal s_clk           : std_logic := '0';
    signal s_reset         : std_logic := '1';
    
    signal s_reg_dst       : std_logic := '0';
    signal s_alu_src       : std_logic := '0';
    signal s_mem_to_reg    : std_logic := '0';
    signal s_reg_write     : std_logic := '0';
    signal s_mem_read      : std_logic := '0';
    signal s_mem_write     : std_logic := '0';
    signal s_alu_control   : std_logic_vector(2 downto 0) := "000";
    
    signal s_instruction   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_alu_result    : std_logic_vector(31 downto 0);

    -- Constante do Clock
    constant clk_period : time := 10 ns;

begin

    -- 3. Instanciação do Datapath (Unit Under Test - UUT)
    uut: data_path port map (
        clk         => s_clk,
        reset       => s_reset,
        reg_dst     => s_reg_dst,
        alu_src     => s_alu_src,
        mem_to_reg  => s_mem_to_reg,
        reg_write   => s_reg_write,
        mem_read    => s_mem_read,
        mem_write   => s_mem_write,
        alu_control => s_alu_control,
        instruction => s_instruction,
        alu_result  => s_alu_result
    );

    -- 4. Processo do Clock
    proc_clk : process
    begin
        while true loop
            s_clk <= '0';
            wait for clk_period / 2;
            s_clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- 5. Processo de Estímulo (O CÉREBRO)
    stimulus_process : process
    begin
        s_reset <= '1';
        wait for 20 ns;
        s_reset <= '0';  -- desativa o reset

        -- ==========================================================
        -- PREPARAÇÃO 1: ADDI $t1, $zero, 10
        -- Carregar valor 10 no registrador 9 ($t1)
        -- Opcode ADDI | rs=$0(0) | rt=$t1(9) | imed=10
        -- ==========================================================
        -- Binário Instrução: 001000 00000 01001 0000000000001010
        s_instruction <= "00101010100011000000000000000000"; 
        
        -- Sinais de Controle para ADDI:
        s_reg_dst     <= '0';   -- Escreve em Rt
        s_alu_src     <= '1';   -- Usa o imediato (10)
        s_mem_to_reg  <= '0';   -- Resultado da ALU vai pro reg
        s_reg_write   <= '1';   -- Habilita escrita
        s_mem_read    <= '0';
        s_mem_write   <= '0';
        s_alu_control <= "010"; -- Código para SOMA (ADD)
        
        wait for clk_period; -- Espera o ciclo terminar e gravar

        -- ==========================================================
        -- PREPARAÇÃO 2: ADDI $t2, $zero, 5
        -- Carregar valor 5 no registrador 10 ($t2)
        -- Opcode ADDI | rs=$0(0) | rt=$t2(10) | imed=5
        -- ==========================================================
        -- Binário Instrução: 001000 00000 01010 0000000000000101
        s_instruction <= x"200A0005";
        
        -- Sinais de Controle (mesmos do ADDI anterior):
        -- (Não preciso mudar nada, pois é a mesma operação, só muda instrução)
        
        wait for clk_period;

        -- ==========================================================
        -- O TESTE REAL: ADD $t3, $t1, $t2
        -- Somar 10 + 5. Resultado deve ir para $t3 (reg 11)
        -- Opcode R-Type | rs=$t1(9) | rt=$t2(10) | rd=$t3(11) | shamt | funct ADD
        -- 000000 01001 01010 01011 00000 100000
        -- ==========================================================
        s_instruction <= x"012A5820";
        
        -- Sinais de Controle para ADD (R-Type):
        s_reg_dst     <= '1';   -- Escreve em Rd ($t3)
        s_alu_src     <= '0';   -- Usa registrador (Rt) na entrada B
        s_mem_to_reg  <= '0';   -- Resultado da ALU vai pro reg
        s_reg_write   <= '1';   -- Habilita escrita
        s_mem_read    <= '0';
        s_mem_write   <= '0';
        s_alu_control <= "010"; -- Código para SOMA
        
        wait for clk_period;

        -- ==========================================================
        -- VERIFICAÇÃO AUTOMÁTICA
        -- ==========================================================
        -- O resultado na porta alu_result deve ser 15 (0x0F)
        assert s_alu_result = x"0000000F"
            report "ERRO: A soma falhou! Esperado 15, Recebido " & integer'image(to_integer(unsigned(s_alu_result)))
            severity error;
            
        -- Se passar, mostra mensagem
        if s_alu_result = x"0000000F" then
            report "SUCESSO: Soma executada corretamente (10 + 5 = 15)." severity note;
        end if;

        wait for 100 ns;
        report "fim da simulação" severity note;
        wait;
    end process;

end behavior;