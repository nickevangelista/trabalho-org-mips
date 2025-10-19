LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY toplevel IS
    PORT (
        clk : IN  std_logic;
        rst : IN  std_logic
    );
END ENTITY toplevel;

ARCHITECTURE structural OF toplevel IS

    -- Constantes para largura de dados e endereços
    constant C_DATA_WIDTH : integer := 32;
    constant C_ADDR_WIDTH : integer := 10;
    constant C_REG_ADDR_WIDTH : integer := 4;

    ---------------------------------------------------------------------------
    -- 1. DECLARAÇÃO DOS COMPONENTES (Seus arquivos VHDL)
    ---------------------------------------------------------------------------

    -- Unidade de Lógica e Aritmética
    COMPONENT alu IS
        Port (
            a       : in  STD_LOGIC_VECTOR(31 downto 0);
            b       : in  STD_LOGIC_VECTOR(31 downto 0);
            alu_op  : in  STD_LOGIC_VECTOR(3 downto 0);
            result  : out STD_LOGIC_VECTOR(31 downto 0);
            zero    : out std_logic
        );
    END COMPONENT;

    -- Unidade de Controle (FSM)
    COMPONENT control_unit IS
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            opcode      : in  std_logic_vector(3 downto 0);
            pc_we       : out std_logic;
            reg_inst_we : out std_logic;
            reg_a_we    : out std_logic;
            reg_b_we    : out std_logic;
            reg_data_we : out std_logic;
            ula_out_we  : out std_logic;
            regfile_we  : out std_logic;
            mem_we      : out std_logic;
            ALUSrcB     : out std_logic;
            MemToReg    : out std_logic;
            alu_sel     : out std_logic_vector(2 downto 0);
            is_jump     : out std_logic;
            is_branch   : out std_logic;
            flag_sel    : out std_logic_vector(1 downto 0)
        );
    END COMPONENT;

    -- Registrador Genérico (Usado para PC, Reg_Inst, Reg_Data, Reg_A, Reg_B, ULA_out)
    COMPONENT temp_reg IS
        generic (
            N : integer := 32
        );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            we  : in  std_logic;
            d   : in  std_logic_vector(N-1 downto 0);
            q   : out std_logic_vector(N-1 downto 0)
        );
    END COMPONENT;

    -- Memória Principal (Dual Port)
    COMPONENT memory_dual_port IS
        GENERIC (
            DATA_WIDTH : integer := 32;
            ADDR_WIDTH : integer := 10
        );
        PORT (
            clk        : IN  std_logic;
            addr_a     : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
            data_out_a : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
            addr_b     : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
            wr_en_b    : IN  std_logic;
            data_in_b  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
            data_out_b : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    -- Mux de Write-Back (MemToReg)
    COMPONENT mux_data IS
        port(
            alu_in  : in  std_logic_vector(31 downto 0);
            mem_in  : in  std_logic_vector(31 downto 0);
            sel     : in  std_logic;
            mux_out : out std_logic_vector(31 downto 0)
        );
    END COMPONENT;

    -- Mux do PC
    COMPONENT mux_pc IS
        port(
            pc_plus4    : in  std_logic_vector(31 downto 0);
            branch_addr : in  std_logic_vector(31 downto 0);
            jump_target : in  std_logic_vector(31 downto 0);
            zero_flag   : in  std_logic;
            is_branch   : in  std_logic;
            is_jump     : in  std_logic;
            pc_next     : out std_logic_vector(31 downto 0)
        );
    END COMPONENT;

    -- Banco de Registradores
    COMPONENT reg_file IS
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            rs_addr     : in  std_logic_vector(3 downto 0);
            rt_addr     : in  std_logic_vector(3 downto 0);
            rd_addr     : in  std_logic_vector(3 downto 0);
            rd_data_in  : in  std_logic_vector(31 downto 0);
            rs_data_out : out std_logic_vector(31 downto 0);
            rt_data_out : out std_logic_vector(31 downto 0);
            Write_Enable: in  std_logic
        );
    END COMPONENT;

    -- Somador (PC + 4)
    COMPONENT somador IS
        port(
            somador_in  : in  std_logic_vector(31 downto 0);
            somador_out : out std_logic_vector(31 downto 0)
        );
    END COMPONENT;

    -- Subtrator (BEQ)
    COMPONENT subtrator_beq IS
        port(
            a      : in  std_logic_vector(31 downto 0);
            b      : in  std_logic_vector(31 downto 0);
            result : out std_logic_vector(31 downto 0);
            zero   : out std_logic
        );
    END COMPONENT;

    ---------------------------------------------------------------------------
    -- 2. SINAIS (Os "Fios" que conectam os componentes)
    ---------------------------------------------------------------------------

    -- Sinais da Unidade de Controle
    signal s_pc_we, s_reg_inst_we, s_reg_a_we, s_reg_b_we, s_reg_data_we, s_ula_out_we, s_regfile_we, s_mem_we  : std_logic;
    signal s_ALUSrcB, s_MemToReg, s_is_jump, s_is_branch : std_logic;
    signal s_alu_sel  : std_logic_vector(2 downto 0);
    signal s_flag_sel : std_logic_vector(1 downto 0);
    signal s_alu_op_wire : std_logic_vector(3 downto 0); -- Fio para corrigir 3-bits -> 4-bits

    -- Sinais do Caminho do PC
    signal s_pc_out, s_pc_next, s_pc_plus_4 : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_beq_zero : std_logic;

    -- Sinais do Caminho de Instrução
    signal s_inst_addr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    signal s_inst      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_inst_out  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_opcode    : std_logic_vector(C_REG_ADDR_WIDTH-1 downto 0);
    signal s_rs_addr, s_rt_addr, s_rd_addr : std_logic_vector(C_REG_ADDR_WIDTH-1 downto 0);
    signal s_immediate : std_logic_vector(C_DATA_WIDTH-1 downto 0);

    -- Sinais do Banco de Registradores (Regs)
    signal s_rs_data, s_rt_data, s_write_data_regfile : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    
    -- Sinais dos Registradores Temporários
    signal s_reg_a_out, s_reg_b_out, s_ula_out, s_ula_out_reg_out, s_reg_data_out : std_logic_vector(C_DATA_WIDTH-1 downto 0);

    -- Sinais do Caminho da ULA
    signal s_ula_in_b : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal s_ula_zero : std_logic; -- (Não utilizado, mas a ULA gera)

    -- Sinais do Caminho da Memória de Dados
    signal s_data_mem_addr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    signal s_mem_data_out  : std_logic_vector(C_DATA_WIDTH-1 downto 0);


BEGIN

    ---------------------------------------------------------------------------
    -- 3. INSTANCIAÇÃO (Conectando os fios)
    ---------------------------------------------------------------------------

    -- Unidade de Controle
    UC_UUT : control_unit
        port map (
            clk         => clk,
            rst         => rst,
            opcode      => s_opcode,
            pc_we       => s_pc_we,
            reg_inst_we => s_reg_inst_we,
            reg_a_we    => s_reg_a_we,
            reg_b_we    => s_reg_b_we,
            reg_data_we => s_reg_data_we,
            ula_out_we  => s_ula_out_we,
            regfile_we  => s_regfile_we,
            mem_we      => s_mem_we,
            ALUSrcB     => s_ALUSrcB,
            MemToReg    => s_MemToReg,
            alu_sel     => s_alu_sel,
            is_jump     => s_is_jump,
            is_branch   => s_is_branch,
            flag_sel    => s_flag_sel -- (Não utilizado por outros componentes, mas gerado)
        );

    -- CAMINHO DO PC
    -- Registrador PC (Usando temp_reg com WE)
    PC_reg : temp_reg
        generic map ( N => C_DATA_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            we  => s_pc_we,
            d   => s_pc_next,
            q   => s_pc_out
        );

    -- Somador (PC + 4)
    PC_somador : somador
        port map (
            somador_in  => s_pc_out,
            somador_out => s_pc_plus_4
        );

    -- Subtrator (BEQ)
    Subtrator_BEQ_UUT : subtrator_beq
        port map (
            a      => s_reg_a_out,
            b      => s_reg_b_out,
            result => open, -- (Não utilizado)
            zero   => s_beq_zero
        );

    -- Mux do PC
    PC_mux : mux_pc
        port map (
            pc_plus4    => s_pc_plus_4,
            branch_addr => s_ula_out_reg_out, -- (Endereço de branch vem da ULA, conforme diagrama)
            jump_target => s_ula_out_reg_out, -- (Endereço de jump também)
            zero_flag   => s_beq_zero,
            is_branch   => s_is_branch,
            is_jump     => s_is_jump,
            pc_next     => s_pc_next
        );

    -- CAMINHO DE BUSCA E DECODIFICAÇÃO
    -- Memória (Porta A para Instruções)
    Memoria_UUT : memory_dual_port
        generic map (
            DATA_WIDTH => C_DATA_WIDTH,
            ADDR_WIDTH => C_ADDR_WIDTH
        )
        port map (
            clk        => clk,
            -- Porta A (Instruções)
            addr_a     => s_pc_out(C_ADDR_WIDTH - 1 DOWNTO 0), -- Trunca PC de 32 para 10 bits
            data_out_a => s_inst,
            -- Porta B (Dados)
            addr_b     => s_ula_out_reg_out(C_ADDR_WIDTH - 1 DOWNTO 0), -- Endereço vem da ULA
            wr_en_b    => s_mem_we,
            data_in_b  => s_reg_b_out, -- Dado para SW vem do Reg_B (via rt)
            data_out_b => s_mem_data_out
        );

    -- Registrador de Instrução (Reg_Inst)
    Reg_Inst_UUT : temp_reg
        generic map ( N => C_DATA_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            we  => s_reg_inst_we,
            d   => s_inst,
            q   => s_inst_out
        );
        
    -- Decodificação dos campos da instrução
    s_opcode  <= s_inst_out(31 downto 28);
    s_rs_addr <= s_inst_out(27 downto 24); -- REG operando 1 / REG base
    s_rt_addr <= s_inst_out(23 downto 20); -- REG operando 2 / Outro comparador
    s_rd_addr <= s_inst_out(19 downto 16); -- REG destino
    s_immediate <= std_logic_vector(resize(signed(s_inst_out(15 downto 0)), C_DATA_WIDTH)); -- Extensão de sinal do imediato (Tipo I)

    -- CAMINHO DE EXECUÇÃO
    -- Banco de Registradores (Regs)
    RegFile_UUT : reg_file
        port map (
            clk         => clk,
            rst         => rst,
            rs_addr     => s_rs_addr,
            rt_addr     => s_rt_addr,
            rd_addr     => s_rd_addr,
            rd_data_in  => s_write_data_regfile,
            rs_data_out => s_rs_data,
            rt_data_out => s_rt_data,
            Write_Enable=> s_regfile_we
        );

    -- Registrador Temp A
    Reg_A_UUT : temp_reg
        generic map ( N => C_DATA_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            we  => s_reg_a_we,
            d   => s_rs_data,
            q   => s_reg_a_out
        );

    -- Registrador Temp B
    Reg_B_UUT : temp_reg
        generic map ( N => C_DATA_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            we  => s_reg_b_we,
            d   => s_rt_data,
            q   => s_reg_b_out
        );
        
    -- Mux da ULA (ALUSrcB) - (Implementado manualmente)
    s_ula_in_b <= s_reg_b_out WHEN s_ALUSrcB = '0' ELSE s_immediate;
    
    -- Fio de correção (3-bit sel -> 4-bit op)
    s_alu_op_wire <= '0' & s_alu_sel;

    -- ULA
    ULA_UUT : alu
        port map (
            a      => s_reg_a_out,
            b      => s_ula_in_b,
            alu_op => s_alu_op_wire,
            result => s_ula_out,
            zero   => s_ula_zero -- (Não usado pela UC, mas usado pelo Subtrator)
        );

    -- Registrador Temp ULA_out
    Reg_ULA_out_UUT : temp_reg
        generic map ( N => C_DATA_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            we  => s_ula_out_we,
            d   => s_ula_out,
            q   => s_ula_out_reg_out
        );

    -- CAMINHO DE MEMÓRIA E WRITE-BACK
    -- Registrador de Dados da Memória (Reg_Data)
    Reg_Data_UUT : temp_reg
        generic map ( N => C_DATA_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            we  => s_reg_data_we,
            d   => s_mem_data_out,
            q   => s_reg_data_out
        );

    -- Mux de Write-Back (MemToReg)
    Mux_WriteBack_UUT : mux_data
        port map (
            alu_in  => s_ula_out_reg_out,
            mem_in  => s_reg_data_out,
            sel     => s_MemToReg,
            mux_out => s_write_data_regfile
        );

END ARCHITECTURE structural;