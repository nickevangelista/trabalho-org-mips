LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; -- Necess�rio para somar e estender sinais

-------------------------------------------------------------------------------
-- ENTITY: toplevel
-- Descri��o: O "toplevel" que conecta todos os componentes do processador MIPS.
-- Este � um design Harvard (mem�rias separadas para dados e instru��es)
-- de ciclo-�nico, que implementa a "Op��o B" (endere��vel por palavra).
-------------------------------------------------------------------------------
ENTITY toplevel IS
    PORT (
        clk   : IN  std_logic; -- Clock global
        reset : IN  std_logic  -- Reset global (ativo em '1')
    );
END ENTITY toplevel;

ARCHITECTURE structural OF toplevel IS

    -- CONSTANTES (Baseado na Op��o B e no seu memory.vhd)
    constant C_DATA_WIDTH : integer := 32;
    constant C_ADDR_WIDTH : integer := 10; -- 1024 posi��es de mem�ria
    constant C_MEM_DATA_START : integer := 512; -- Parti��o da mem�ria

    ---------------------------------------------------------------------------
    -- DECLARA��O DOS COMPONENTES (Seus outros arquivos .vhd)
    ---------------------------------------------------------------------------

    -- Assumindo que seu pc.vhd � um registrador gen�rico
    COMPONENT generic_register IS
        GENERIC ( WIDTH : integer := C_DATA_WIDTH );
        PORT (
            clk   : IN  std_logic;
            reset : IN  std_logic;
            d_in  : IN  std_logic_vector(WIDTH - 1 DOWNTO 0);
            q_out : OUT std_logic_vector(WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    -- Mem�ria (o arquivo que eu criei para voc�)
    COMPONENT memory IS
        GENERIC ( DATA_WIDTH : integer := C_DATA_WIDTH; ADDR_WIDTH : integer := C_ADDR_WIDTH );
        PORT (
            clk      : IN  std_logic;
            wr_en    : IN  std_logic;
            addr     : IN  std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
            data_in  : IN  std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
            data_out : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    -- Banco de Registradores
    COMPONENT reg_file IS
        PORT (
            clk         : IN  std_logic;
            RegWrite    : IN  std_logic; -- Sinal de controle
            read_addr_1 : IN  std_logic_vector(4 DOWNTO 0); -- instr(25-21)
            read_addr_2 : IN  std_logic_vector(4 DOWNTO 0); -- instr(20-16)
            write_addr  : IN  std_logic_vector(4 DOWNTO 0); -- Mux (15-11 ou 20-16)
            write_data  : IN  std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
            read_data_1 : OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
            read_data_2 : OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    -- Unidade de Controle Principal
    COMPONENT control_unit IS
        PORT (
            opcode   : IN  std_logic_vector(5 DOWNTO 0); -- instr(31-26)
            -- Sinais de controle de sa�da
            RegDst   : OUT std_logic; -- '1' para RD, '0' para RT
            RegWrite : OUT std_logic;
            ALUSrc   : OUT std_logic; -- '0' para Reg, '1' para Imediato
            MemWrite : OUT std_logic;
            MemtoReg : OUT std_logic; -- '0' para ALU, '1' para Mem�ria
            Branch   : OUT std_logic;
            Jump     : OUT std_logic;
            ALUOp    : OUT std_logic_vector(3 DOWNTO 0) -- Assumindo que a CU gera o OP da ALU
        );
    END COMPONENT;

    -- Unidade L�gica e Aritm�tica (ULA)
    COMPONENT alu IS
        PORT (
            a      : IN  std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
            b      : IN  std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
            alu_op : IN  std_logic_vector(3 DOWNTO 0);
            result : OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
            zero   : OUT std_logic -- Flag 'Zero' para o BEQ
        );
    END COMPONENT;

    ---------------------------------------------------------------------------
    -- SINAIS (os "fios" que conectam tudo)
    ---------------------------------------------------------------------------
    -- Sinais do PC e Fetch
    SIGNAL s_pc_current       : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0); -- Sa�da do PC
    SIGNAL s_pc_next          : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0); -- Entrada do PC
    SIGNAL s_pc_plus_1        : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_pc_branch_target : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_pc_jump_target   : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);

    -- Sinais da Instru��o e Controle
    SIGNAL s_instruction : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_imm_extended : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);

    -- Sinais de Controle (sa�das da CU)
    SIGNAL s_RegDst   : std_logic;
    SIGNAL s_RegWrite : std_logic;
    SIGNAL s_ALUSrc   : std_logic;
    SIGNAL s_MemWrite : std_logic;
    SIGNAL s_MemtoReg : std_logic;
    SIGNAL s_Branch   : std_logic;
    SIGNAL s_Jump     : std_logic;
    SIGNAL s_ALUOp    : std_logic_vector(3 DOWNTO 0);
    SIGNAL s_Branch_taken : std_logic;

    -- Sinais do Banco de Registradores
    SIGNAL s_reg_write_addr : std_logic_vector(4 DOWNTO 0);
    SIGNAL s_reg_write_data : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_reg_read_data_1 : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_reg_read_data_2 : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);

    -- Sinais da ALU
    SIGNAL s_alu_in_2 : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_alu_result : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL s_alu_zero : std_logic;

    -- Sinais da Mem�ria de Dados
    SIGNAL s_mem_read_data : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);

BEGIN

    ---------------------------------------------------------------------------
    -- 1. EST�GIO DE BUSCA (FETCH)
    ---------------------------------------------------------------------------
    -- Instancia o Program Counter (PC)
    PC_reg : COMPONENT generic_register
        GENERIC MAP ( WIDTH => C_DATA_WIDTH )
        PORT MAP (
            clk   => clk,
            reset => reset,
            d_in  => s_pc_next,
            q_out => s_pc_current
        );

    -- Calcula PC + 1 (Implementa��o da Op��o B)
    s_pc_plus_1 <= std_logic_vector(unsigned(s_pc_current) + 1);

    -- Instancia a Mem�ria de Instru��es (Read-Only)
    -- NOTA: Esta � a "metade" da mem�ria (0-511)
    Instr_Mem : COMPONENT memory
        GENERIC MAP ( DATA_WIDTH => C_DATA_WIDTH, ADDR_WIDTH => C_ADDR_WIDTH )
        PORT MAP (
            clk      => clk,
            wr_en    => '0', -- Nunca escreve na mem�ria de instru��es
            addr     => s_pc_current(C_ADDR_WIDTH - 1 DOWNTO 0), -- Usa os 10 bits do PC
            data_in  => (OTHERS => '0'),
            data_out => s_instruction
        );

    ---------------------------------------------------------------------------
    -- 2. EST�GIO DE DECODIFICA��O (DECODE)
    ---------------------------------------------------------------------------
    -- Instancia a Unidade de Controle
    CU : COMPONENT control_unit
        PORT MAP (
            opcode   => s_instruction(31 DOWNTO 26),
            RegDst   => s_RegDst,
            RegWrite => s_RegWrite,
            ALUSrc   => s_ALUSrc,
            MemWrite => s_MemWrite,
            MemtoReg => s_MemtoReg,
            Branch   => s_Branch,
            Jump     => s_Jump,
            ALUOp    => s_ALUOp
        );

    -- Instancia o Banco de Registradores
    RegFile_inst : COMPONENT reg_file
        PORT MAP (
            clk         => clk,
            RegWrite    => s_RegWrite,
            read_addr_1 => s_instruction(25 DOWNTO 21), -- RS
            read_addr_2 => s_instruction(20 DOWNTO 16), -- RT
            write_addr  => s_reg_write_addr,            -- Mux de escrita
            write_data  => s_reg_write_data,            -- Dado que vem do Mux de WriteBack
            read_data_1 => s_reg_read_data_1,           -- Dado 1 (sempre vai para ULA)
            read_data_2 => s_reg_read_data_2            -- Dado 2 (vai para ULA ou Mem�ria)
        );

    -- Mux para o Endere�o de Escrita (RegDst)
    -- Se RegDst='1' (R-type), escreve em RD (15-11)
    -- Se RegDst='0' (I-type), escreve em RT (20-16)
    s_reg_write_addr <= s_instruction(15 DOWNTO 11) WHEN s_RegDst = '1' ELSE
                        s_instruction(20 DOWNTO 16);

    ---------------------------------------------------------------------------
    -- 3. EST�GIO DE EXECU��O (EXECUTE)
    ---------------------------------------------------------------------------
    -- Extensor de Sinal para o imediato (16 bits -> 32 bits)
    s_imm_extended <= std_logic_vector(resize(signed(s_instruction(15 DOWNTO 0)), C_DATA_WIDTH));

    -- Mux da Fonte da ULA (ALUSrc)
    -- Se ALUSrc='1' (I-type), usa o imediato estendido
    -- Se ALUSrc='0' (R-type), usa o registrador (Read Data 2)
    s_alu_in_2 <= s_imm_extended WHEN s_ALUSrc = '1' ELSE
                  s_reg_read_data_2;

    -- Instancia a ULA (ALU)
    ALU_inst : COMPONENT alu
        PORT MAP (
            a      => s_reg_read_data_1, -- Sempre vem do RegFile
            b      => s_alu_in_2,        -- Vem do Mux ALUSrc
            alu_op => s_ALUOp,           -- Vem da Unidade de Controle
            result => s_alu_result,      -- Sa�da da ULA
            zero   => s_alu_zero         -- Flag 'zero'
        );

    ---------------------------------------------------------------------------
    -- 4. EST�GIO DE MEM�RIA (MEMORY)
    ---------------------------------------------------------------------------
    -- Instancia a Mem�ria de Dados (Read/Write)
    -- NOTA: Esta � a "outra metade" da mem�ria (512-1023)
    Data_Mem : COMPONENT memory
        GENERIC MAP ( DATA_WIDTH => C_DATA_WIDTH, ADDR_WIDTH => C_ADDR_WIDTH )
        PORT MAP (
            clk      => clk,
            wr_en    => s_MemWrite,      -- Sinal de controle 'sw'
            addr     => s_alu_result(C_ADDR_WIDTH - 1 DOWNTO 0), -- Endere�o vem da ULA
            data_in  => s_reg_read_data_2, -- Dado a ser escrito (vem do RegFile)
            data_out => s_mem_read_data  -- Dado lido (para 'lw')
        );
    -- NOTA: O endere�o da mem�ria de dados s_alu_result(9 DOWNTO 0)
    -- j� deve ter o offset 512 somado (isso � feito no programa assembly/ULA)

    ---------------------------------------------------------------------------
    -- 5. EST�GIO DE ESCRITA (WRITE-BACK)
    ---------------------------------------------------------------------------
    -- Mux de Write-Back (MemtoReg)
    -- Se MemtoReg='1' (lw), escreve o dado da mem�ria
    -- Se MemtoReg='0' (R-type/addi), escreve o resultado da ULA
    s_reg_write_data <= s_mem_read_data WHEN s_MemtoReg = '1' ELSE
                        s_alu_result;

    ---------------------------------------------------------------------------
    -- 6. L�GICA DE ATUALIZA��O DO PC (Op��o B)
    ---------------------------------------------------------------------------
    -- C�lculo do Endere�o de Desvio (Branch Target)
    -- PC_target = (PC + 1) + imediato_estendido
    s_pc_branch_target <= std_logic_vector(signed(s_pc_plus_1) + signed(s_imm_extended));

    -- C�lculo do Endere�o de Pulo (Jump Target)
    -- PC_target = { (PC+1)[31:26], instr[25:0] }
    s_pc_jump_target <= s_pc_plus_1(31 DOWNTO 26) & s_instruction(25 DOWNTO 0);

    -- L�gica de decis�o do Branch (BEQ)
    s_Branch_taken <= s_Branch AND s_alu_zero;

    -- Mux Final do PC
    -- Seleciona qual ser� o PR�XIMO valor do PC
    WITH s_Jump SELECT
        s_pc_next <= s_pc_jump_target WHEN '1',     -- Prioridade 1: Jump
                     s_pc_branch_target WHEN '0' WHEN s_Branch_taken = '1', -- Prioridade 2: Branch (se for pego)
                     s_pc_plus_1        WHEN OTHERS; -- Padr�o: PC + 1

END ARCHITECTURE structural;