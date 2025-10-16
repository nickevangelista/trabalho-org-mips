-- Importa as bibliotecas básicas do VHDL
LIBRARY ieee;
USE ieee.std_logic_1164.all; -- Para o tipo std_logic
USE ieee.numeric_std.all;    -- Para operações matemáticas (unsigned, signed, resize)

-- ENTIDADE (Define as "portas" de entrada/saída do processador)
ENTITY toplevel IS
    PORT (
        clk   : IN  std_logic; -- Sinal de clock global
        reset : IN  std_logic  -- Sinal de reset global
    );
END ENTITY toplevel;

-- ARQUITETURA (Define o funcionamento interno, conectando os blocos)
ARCHITECTURE structural OF toplevel IS

    -- CONSTANTES (Valores fixos para o projeto)
    constant C_DATA_WIDTH     : integer := 32; -- Largura dos dados (32 bits)
    constant C_ADDR_WIDTH     : integer := 10; -- Largura do endereço (10 bits = 1024 posições)
    -- *** Constante para a partição da memória ***
    constant C_DATA_BASE_ADDR : integer := 512; -- Endereço onde os dados começam

    ---------------------------------------------------------------------------
    -- DECLARAÇÃO DOS COMPONENTES (Caixas-pretas que vamos usar)
    ---------------------------------------------------------------------------
    
    -- Componente: Registrador Genérico (usado para o PC)
    COMPONENT generic_register IS
        GENERIC ( WIDTH : integer := C_DATA_WIDTH );
        PORT ( clk : IN std_logic; reset : IN std_logic;
               d_in : IN std_logic_vector(WIDTH-1 DOWNTO 0);
               q_out : OUT std_logic_vector(WIDTH-1 DOWNTO 0) );
    END COMPONENT;

    -- Componente: Memória de Porta Dupla
    COMPONENT memory_dual_port IS
        GENERIC ( DATA_WIDTH : integer := C_DATA_WIDTH; ADDR_WIDTH : integer := C_ADDR_WIDTH );
        PORT ( clk : IN std_logic;
               -- Porta A (só leitura, para instruções)
               addr_a   : IN  std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
               data_out_a : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
               -- Porta B (leitura/escrita, para dados)
               addr_b   : IN  std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
               wr_en_b  : IN  std_logic;
               data_in_b  : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
               data_out_b : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0) );
    END COMPONENT;

    -- Componente: Banco de Registradores (RegFile)
    COMPONENT reg_file IS
        PORT ( clk : IN std_logic; RegWrite : IN std_logic;
               read_addr_1 : IN std_logic_vector(4 DOWNTO 0); read_addr_2 : IN std_logic_vector(4 DOWNTO 0);
               write_addr  : IN std_logic_vector(4 DOWNTO 0); write_data  : IN std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
               read_data_1 : OUT std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0); read_data_2 : OUT std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0) );
    END COMPONENT;

    -- Componente: Unidade de Controle
    COMPONENT control_unit IS
        PORT ( opcode : IN std_logic_vector(5 DOWNTO 0);
               RegDst : OUT std_logic; RegWrite : OUT std_logic; ALUSrc : OUT std_logic; 
               MemWrite : OUT std_logic; MemtoReg : OUT std_logic; Branch : OUT std_logic;
               Jump : OUT std_logic; ALUOp : OUT std_logic_vector(3 DOWNTO 0) );
    END COMPONENT;

    -- Componente: ULA (Unidade Lógica e Aritmética)
    COMPONENT alu IS
        PORT ( a : IN std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0); b : IN std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
               alu_op : IN std_logic_vector(3 DOWNTO 0);
               result : OUT std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0); zero : OUT std_logic );
    END COMPONENT;
    
    ---------------------------------------------------------------------------
    -- SINAIS (os "fios" que conectam os componentes)
    ---------------------------------------------------------------------------
    -- Fios do PC (Program Counter)
    SIGNAL s_pc_current, s_pc_next, s_pc_plus_1 : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_pc_branch_target, s_pc_jump_target : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    
    -- Fio da Instrução
    SIGNAL s_instruction : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    
    -- Fio do Imediato (estendido de 16 para 32 bits)
    SIGNAL s_imm_extended : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    
    -- Fios dos Sinais de Controle (vindos da Unidade de Controle)
    SIGNAL s_RegDst, s_RegWrite, s_ALUSrc, s_MemWrite, s_MemtoReg, s_Branch, s_Jump, s_Branch_taken, s_alu_zero : std_logic;
    SIGNAL s_ALUOp : std_logic_vector(3 DOWNTO 0);
    
    -- Fios do Banco de Registradores
    SIGNAL s_reg_write_addr : std_logic_vector(4 DOWNTO 0);
    SIGNAL s_reg_write_data : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL s_reg_read_data_1, s_reg_read_data_2 : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    
    -- Fios da ULA
    SIGNAL s_alu_in_2, s_alu_result : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);
    
    -- Fio da Memória (dado lido)
    SIGNAL s_mem_read_data : std_logic_vector(C_DATA_WIDTH-1 DOWNTO 0);

    -- *** NOVOS FIOS PARA O CÁLCULO DA PARTIÇÃO ***
    -- Constante 512 (base de dados) como um vetor de 10 bits ("1000000000")
    CONSTANT C_DATA_BASE_VEC : std_logic_vector(C_ADDR_WIDTH - 1 DOWNTO 0) := 
        std_logic_vector(to_unsigned(C_DATA_BASE_ADDR, C_ADDR_WIDTH));
        
    -- O "fio" que leva o endereço de dados REAL (calculado) para a Memória
    SIGNAL s_data_mem_addr : std_logic_vector(C_ADDR_WIDTH - 1 DOWNTO 0);


BEGIN -- Início da lógica (conexões)

    ---------------------------------------------------------------------------
    -- 1. ESTÁGIO DE BUSCA (FETCH)
    ---------------------------------------------------------------------------
    -- Instancia o Registrador PC
    Registrador_PC : COMPONENT generic_register
        GENERIC MAP ( WIDTH => C_DATA_WIDTH )
        PORT MAP ( clk => clk, reset => reset, d_in => s_pc_next, q_out => s_pc_current );

    -- Calcula PC + 1 (Opção B: endereçamento por palavra)
    s_pc_plus_1 <= std_logic_vector(unsigned(s_pc_current) + 1);

    ---------------------------------------------------------------------------
    -- INSTÂNCIA DA MEMÓRIA ÚNICA (Porta-Dupla)
    ---------------------------------------------------------------------------
    Memoria_Unica : COMPONENT memory_dual_port
        GENERIC MAP ( DATA_WIDTH => C_DATA_WIDTH, ADDR_WIDTH => C_ADDR_WIDTH )
        PORT MAP (
            clk      => clk,
            
            -- Porta A (Busca de Instrução): Conectada ao PC
            addr_a   => s_pc_current(C_ADDR_WIDTH - 1 DOWNTO 0),
            data_out_a => s_instruction, -- Sai a instrução

            -- Porta B (Acesso a Dados): Conectada ao Somador de Partição
            addr_b   => s_data_mem_addr, -- <--- Conectado ao novo fio!
            wr_en_b  => s_MemWrite,      -- Sinal de controle para 'sw'
            data_in_b  => s_reg_read_data_2, -- Dado que vem do RegFile para 'sw'
            data_out_b => s_mem_read_data  -- Dado que sai da memória para 'lw'
        );

    ---------------------------------------------------------------------------
    -- 2. ESTÁGIO DE DECODIFICAÇÃO (DECODE)
    ---------------------------------------------------------------------------
    -- Instancia a Unidade de Controle
    Unidade_Controle : COMPONENT control_unit
        PORT MAP ( opcode => s_instruction(31 DOWNTO 26), -- Envia o opcode
                   -- Recebe os sinais de controle
                   RegDst => s_RegDst, RegWrite => s_RegWrite, ALUSrc => s_ALUSrc,
                   MemWrite => s_MemWrite, MemtoReg => s_MemtoReg, Branch => s_Branch,
                   Jump => s_Jump, ALUOp => s_ALUOp );

    -- Instancia o Banco de Registradores
    Banco_de_Registradores : COMPONENT reg_file
        PORT MAP ( clk => clk, RegWrite => s_RegWrite,
                   read_addr_1 => s_instruction(25 DOWNTO 21), -- Endereço RS
                   read_addr_2 => s_instruction(20 DOWNTO 16), -- Endereço RT
                   write_addr  => s_reg_write_addr,            -- Onde escrever (decidido pelo MUX)
                   write_data  => s_reg_write_data,            -- O que escrever (decidido pelo MUX)
                   read_data_1 => s_reg_read_data_1,           -- Sai dado 1
                   read_data_2 => s_reg_read_data_2 );         -- Sai dado 2

    -- MUX (Multiplexador) do Endereço de Escrita (RegDst)
    s_reg_write_addr <= s_instruction(15 DOWNTO 11) WHEN s_RegDst = '1' ELSE -- Tipo-R (usa RD)
                        s_instruction(20 DOWNTO 16);                       -- Tipo-I (usa RT)

    ---------------------------------------------------------------------------
    -- 3. ESTÁGIO DE EXECUÇÃO (EXECUTE)
    ---------------------------------------------------------------------------
    -- Extensor de Sinal (converte 16 bits do imediato para 32 bits, com sinal)
    s_imm_extended <= std_logic_vector(resize(signed(s_instruction(15 DOWNTO 0)), C_DATA_WIDTH));

    -- MUX da segunda entrada da ULA (ALUSrc)
    s_alu_in_2 <= s_imm_extended WHEN s_ALUSrc = '1' ELSE -- Tipo-I (usa imediato)
                  s_reg_read_data_2;                  -- Tipo-R (usa dado 2 do RegFile)

    -- Instancia a ULA
    ULA_Principal : COMPONENT alu
        PORT MAP ( a => s_reg_read_data_1, b => s_alu_in_2, alu_op => s_ALUOp,
                   result => s_alu_result, zero => s_alu_zero );

    ---------------------------------------------------------------------------
    -- 4. ESTÁGIO DE MEMÓRIA (LÓGICA DE PARTIÇÃO)
    ---------------------------------------------------------------------------
    -- *** AQUI ESTÁ A LÓGICA NOVA DA PARTIÇÃO ***
    -- O endereço de dados real é o resultado da ULA (offset) + o endereço base (512).
    s_data_mem_addr <= std_logic_vector(unsigned(s_alu_result(C_ADDR_WIDTH - 1 DOWNTO 0)) + unsigned(C_DATA_BASE_VEC));
    

    ---------------------------------------------------------------------------
    -- 5. ESTÁGIO DE ESCRITA (WRITE-BACK)
    ---------------------------------------------------------------------------
    -- MUX do dado de escrita no Registrador (MemtoReg)
    s_reg_write_data <= s_mem_read_data WHEN s_MemtoReg = '1' ELSE -- 'lw' (usa dado da memória)
                        s_alu_result;                       -- Tipo-R (usa resultado da ULA)

    ---------------------------------------------------------------------------
    -- 6. LÓGICA DE ATUALIZAÇÃO DO PC
    ---------------------------------------------------------------------------
    -- Calcula o endereço do Branch (PC+1 + imediato)
    s_pc_branch_target <= std_logic_vector(signed(s_pc_plus_1) + signed(s_imm_extended));

    -- Calcula o endereço do Jump (concatena 6 bits do PC+1 com 26 da instrução)
    s_pc_jump_target <= s_pc_plus_1(31 DOWNTO 26) & s_instruction(25 DOWNTO 0);

    -- Verifica se o Branch deve ser pego (se Branch='1' E resultado da ULA foi zero)
    s_Branch_taken <= s_Branch AND s_alu_zero;

    -- *** CÓDIGO CORRIGIDO ***
    -- Mux Final do PC (decide qual será o PRÓXIMO PC)
    -- Isso é um MUX com prioridade
    s_pc_next <= s_pc_jump_target   WHEN s_Jump = '1' ELSE         -- Prioridade 1: JUMP
                 s_pc_branch_target   WHEN s_Branch_taken = '1' ELSE -- Prioridade 2: BRANCH (se pego)
                 s_pc_plus_1;                                  -- Padrão: PC + 1

END ARCHITECTURE structural;