-- toplevel.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY toplevel IS
    PORT (
        clk   : IN  std_logic;
        reset : IN  std_logic
    );
END ENTITY toplevel;

ARCHITECTURE structural OF toplevel IS

    constant C_DATA_WIDTH     : integer := 32;
    constant C_ADDR_WIDTH     : integer := 10;
    constant C_DATA_BASE_ADDR : integer := 512;

    ---------------------------------------------------------------------------
    -- DECLARAÇÃO COMPONENTES
    ---------------------------------------------------------------------------
    COMPONENT generic_register IS
        GENERIC ( WIDTH : integer := C_DATA_WIDTH );
        PORT ( clk : IN std_logic; reset : IN std_logic;
               d_in : IN std_logic_vector(WIDTH-1 DOWNTO 0);
               q_out : OUT std_logic_vector(WIDTH-1 DOWNTO 0) );
    END COMPONENT;

    COMPONENT memory_dual_port IS
        GENERIC ( DATA_WIDTH : integer := C_DATA_WIDTH; ADDR_WIDTH : integer := C_ADDR_WIDTH );
        PORT ( clk : IN std_logic;
               addr_a   : IN  std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
               data_out_a : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
               addr_b   : IN  std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
               wr_en_b  : IN  std_logic;
               data_in_b  : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
               data_out_b : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0) );
    END COMPONENT;

    COMPONENT reg_file IS
        PORT ( clk : IN std_logic; RegWrite : IN std_logic;
               read_addr_1 : IN std_logic_vector(4 DOWNTO 0); read_addr_2 : IN std_logic_vector(4 DOWNTO 0);
               write_addr  : IN std_logic_vector(4 DOWNTO 0); write_data  : IN std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
               read_data_1 : OUT std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0); read_data_2 : OUT std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0) );
    END COMPONENT;

    COMPONENT control_unit IS
        PORT ( opcode : IN std_logic_vector(5 DOWNTO 0);
               RegDst : OUT std_logic; RegWrite : OUT std_logic; ALUSrc : OUT std_logic;
               MemWrite : OUT std_logic; MemtoReg : OUT std_logic; Branch : OUT std_logic;
               Jump : OUT std_logic; ALUOp : OUT std_logic_vector(3 DOWNTO 0) );
    END COMPONENT;

    COMPONENT alu IS
        PORT ( a : IN std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
               b : IN std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
               alu_op : IN std_logic_vector(3 DOWNTO 0);
               result : OUT std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
               zero : OUT std_logic );
    END COMPONENT;

    ---------------------------------------------------------------------------
    -- SINAIS
    ---------------------------------------------------------------------------
    SIGNAL s_pc_current, s_pc_next, s_pc_plus_1 : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_pc_branch_target, s_pc_jump_target : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_instruction : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_imm_extended : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);

    SIGNAL s_RegDst, s_RegWrite, s_ALUSrc, s_MemWrite, s_MemtoReg, s_Branch, s_Jump, s_Branch_taken, s_alu_zero : std_logic;
    SIGNAL s_ALUOp : std_logic_vector(3 DOWNTO 0);

    SIGNAL s_reg_write_addr : std_logic_vector(4 DOWNTO 0);
    SIGNAL s_reg_write_data : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_reg_read_data_1, s_reg_read_data_2 : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);

    SIGNAL s_alu_in_2, s_alu_result : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_mem_read_data : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);

    CONSTANT C_DATA_BASE_VEC : std_logic_vector(C_ADDR_WIDTH - 1 DOWNTO 0) := 
        std_logic_vector(to_unsigned(C_DATA_BASE_ADDR, C_ADDR_WIDTH));

    SIGNAL s_data_mem_addr : std_logic_vector(C_ADDR_WIDTH - 1 DOWNTO 0);

BEGIN

    ---------------------------------------------------------------------------
    -- 1. PC Register (assumes generic_register implements synchronous register)
    ---------------------------------------------------------------------------
    Registrador_PC : generic_register
        GENERIC MAP ( WIDTH => C_DATA_WIDTH )
        PORT MAP ( clk => clk, reset => reset, d_in => s_pc_next, q_out => s_pc_current );

    s_pc_plus_1 <= std_logic_vector(unsigned(s_pc_current) + 1);

    ---------------------------------------------------------------------------
    -- Memória (duas portas)
    ---------------------------------------------------------------------------
    Memoria_Unica : memory_dual_port
        GENERIC MAP ( DATA_WIDTH => C_DATA_WIDTH, ADDR_WIDTH => C_ADDR_WIDTH )
        PORT MAP (
            clk       => clk,
            addr_a    => s_pc_current(C_ADDR_WIDTH - 1 DOWNTO 0),
            data_out_a=> s_instruction,
            addr_b    => s_data_mem_addr,
            wr_en_b   => s_MemWrite,
            data_in_b => s_reg_read_data_2,
            data_out_b=> s_mem_read_data
        );

    ---------------------------------------------------------------------------
    -- Unidade de Controle e Banco de Registradores
    ---------------------------------------------------------------------------
    Unidade_Controle : control_unit
        PORT MAP ( opcode => s_instruction(31 DOWNTO 26),
                   RegDst => s_RegDst, RegWrite => s_RegWrite, ALUSrc => s_ALUSrc,
                   MemWrite => s_MemWrite, MemtoReg => s_MemtoReg, Branch => s_Branch,
                   Jump => s_Jump, ALUOp => s_ALUOp );

    Banco_de_Registradores : reg_file
        PORT MAP ( clk => clk, RegWrite => s_RegWrite,
                   read_addr_1 => s_instruction(25 DOWNTO 21),
                   read_addr_2 => s_instruction(20 DOWNTO 16),
                   write_addr  => s_reg_write_addr,
                   write_data  => s_reg_write_data,
                   read_data_1 => s_reg_read_data_1,
                   read_data_2 => s_reg_read_data_2 );

    s_reg_write_addr <= s_instruction(15 DOWNTO 11) WHEN s_RegDst = '1' ELSE s_instruction(20 DOWNTO 16);

    ---------------------------------------------------------------------------
    -- Execução (ULA)
    ---------------------------------------------------------------------------
    s_imm_extended <= std_logic_vector(resize(signed(s_instruction(15 DOWNTO 0)), C_DATA_WIDTH));

    s_alu_in_2 <= s_imm_extended WHEN s_ALUSrc = '1' ELSE s_reg_read_data_2;

    ULA_Principal : alu
        PORT MAP ( a => s_reg_read_data_1, b => s_alu_in_2, alu_op => s_ALUOp,
                   result => s_alu_result, zero => s_alu_zero );

    ---------------------------------------------------------------------------
    -- Partição: transforma resultado ULA (offset) para endereço de dados real
    ---------------------------------------------------------------------------
    s_data_mem_addr <= std_logic_vector(unsigned(s_alu_result(C_ADDR_WIDTH - 1 DOWNTO 0)) + unsigned(C_DATA_BASE_VEC));

    ---------------------------------------------------------------------------
    -- Write-back
    ---------------------------------------------------------------------------
    s_reg_write_data <= s_mem_read_data WHEN s_MemtoReg = '1' ELSE s_alu_result;

    ---------------------------------------------------------------------------
    -- Atualização do PC (Jump / Branch / PC+1)
    ---------------------------------------------------------------------------
    s_pc_branch_target <= std_logic_vector(signed(s_pc_plus_1) + signed(s_imm_extended));
    s_pc_jump_target <= s_pc_plus_1(31 DOWNTO 26) & s_instruction(25 DOWNTO 0);

    s_Branch_taken <= s_Branch AND s_alu_zero;

    s_pc_next <= s_pc_jump_target   WHEN s_Jump = '1' ELSE
                 s_pc_branch_target WHEN s_Branch_taken = '1' ELSE
                 s_pc_plus_1;

END ARCHITECTURE structural;
