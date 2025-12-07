library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity data_path is
    Port(
        clk             :in std_logic;
        reset           :in std_logic;
        Pc              :in std_logic;
        Mem             :in std_logic;
        Regs            :in std_logic;
        ULA_sign        :in std_logic_vector(1 downto 0);
        ULA_Write       :in std_logic;
        Reg_Inst        :in std_logic;
        Reg_Data        :in std_logic;     
        Reg_A           :in std_logic;
        Reg_B           :in std_logic;
        Mux_Data_sign   :in std_logic;
        Mux_PC_sign     :in std_logic_vector(1 downto 0);
        Mux_MEM_sign    :in std_Logic_vector(1 downto 0);
        fio_jump        :in std_logic;
        Zero_out        :out std_logic;
        Opcode_out      :out std_logic_vector(3 downto 0);
        Store_Source    :in std_logic   
        );
end data_path;
    
architecture Behavioral of data_path is

-----------------------------------------------
--       Modulos ja criados

component ula 
    Port (
         a       : in  std_logic_vector(31 downto 0);
         b       : in  std_logic_vector(31 downto 0);
         ula_op  : in  std_logic_vector(1 downto 0); --add (00), sub(01), and(10)
         result  : out std_logic_vector(31 downto 0)
         );
end component;

component Reg_File 
    Port (
         clk                  : in  std_logic;
         rst                  : in  std_logic;
         escreve_reg          : in  std_logic;                       -- Sinal de controle (RegWrite)
         leitura_rs           : in  std_logic_vector(3 downto 0);    -- registrador rs
         leitura_rt           : in  std_logic_vector(3 downto 0);    -- registrador rt
         endereco_escrita     : in  std_logic_vector(3 downto 0);    -- Endereço escrita (rd ou rt)
         escreve_dado         : in  std_logic_vector(31 downto 0);   -- Dado a ser gravado
         leitura_dado1        : out std_logic_vector(31 downto 0);   -- Saída dado 1
         leitura_dado2        : out std_logic_vector(31 downto 0)    -- Saída dado 2
         );    
end component;

component mux_MEM 
    Port (
         sel        : in  std_logic_vector (1 downto 0); -- seletor do mux
         reg_inst_in: in  std_logic_vector (9 downto 0); -- entrada do endereco do load para salvar em um registrador (00)
         pc_in      : in  std_logic_vector (9 downto 0); -- entrada para o pc pegar a proxima instrução ou desviar (01)
         reg_b_in   : in  std_logic_vector (9 downto 0); -- entrada para pegar o endereco do store vindo do reg_b (10)
         addr_out   : out std_logic_vector (9 downto 0)  -- saida para o addr da memoria
         );
end component;

component Somador_PC_4 
    Port(
        somador_in  : in  std_logic_vector(9 downto 0); --Instrução anterior
        somador_out : out std_logic_vector(9 downto 0) -- Soma para ir para a proxima instrução
        );
end component;

component Mux_pc1 
    Port(
        endereco_beq_jmp : in  std_logic_vector(9 downto 0); -- endereço de BEQ ou JUMP
        pc_4             : in  std_logic_vector(9 downto 0); -- incremento do pc
        verifica_beq     : in  std_logic;                    --verifica se o beq é igual a 1
        verifica_jmp     : in  std_logic;                    -- verifica se é para fazer um jmp
        pc_out           : out std_logic_vector(9 downto 0)  -- valor final enviado ao PC
        );
end component;

component Memoria 
    Port(
        clk                    : in  std_logic;
        verifica_escrita       : in  std_logic;                      -- verifica se sera escrito algo na memoria
        addr                   : in  std_logic_vector(9 downto 0);   -- endereco
        data_in                : in  std_logic_vector(31 downto 0);  -- para quando for ser escrito um dado na memoria
        data_out               : out std_logic_vector(31 downto 0)   -- para quando for ser lido um dado na memoria
        );
end component;
      
component Mux_Data 
    Port(
        alu_in       : in  std_logic_vector(31 downto 0); -- dado vindo da ULA
        mem_in       : in  std_logic_vector(31 downto 0); -- dado vindo da memória (reg_data)
        sel          : in  std_logic;                     -- seletor, 1 da ula, 0 da memória
        mux_data_out : out std_logic_vector(31 downto 0)  -- saída selecionada
        );    
end component;    
      
component Subtrator 
    Port(
        a        : in  std_logic_vector(31 downto 0);  -- valor do registrador A
        b        : in  std_logic_vector(31 downto 0);  -- valor do registrador B
        zero_beq : out std_logic                       -- resultado da subtração                  
        );    
end component;   
      
-----------------------------------------------
--        Registradores intermediarios

    signal IR       :std_logic_vector(31 downto 0); -- Registrador de instrução
    signal DR       :std_logic_vector(31 downto 0); -- Registrador de Dado
    signal A        :std_logic_vector(31 downto 0); -- Registrador auxiliar para ula A
    signal B        :std_logic_vector(31 downto 0); -- Registrador auxiliar para ula B
    signal ULA_OUT  :std_logic_vector(31 downto 0); -- Registrador aluOUT para salvar o resultado da ULA

 ----------------------------------------------
 --       Fios da parte operativa
 
    signal PC_in        :std_logic_vector(9 downto 0);  -- Sinal que o pc recebe do Mux_pc
    signal PC_out       :std_logic_vector(9 downto 0);  -- Sinal que o pc envia para o mux_mem
    signal PC_plus_4    :std_logic_vector(9 downto 0);  -- Sinal que sai do somador do pc+4 para o Mux_pc
    signal zero_BEQ     :std_logic;
    signal MEM_ADR      :std_logic_vector(9 downto 0);  -- Sinal que sai do mum_Mem e entra no endereco de mem
    signal MEM_OUT      :std_logic_vector(31 downto 0); -- Sinal que sai da mem e entra no RI E DR
    signal IR_OUT       :std_logic_vector(31 downto 0); -- Sinal que sai do IR e vai para os REGS, Mux_mem E Mux_PC
    signal DR_OUT       :std_logic_vector(31 downto 0); -- Sinal que sai do DR e vai para a porta 01 do Mux_Data
    signal Mux_Data_OUT :std_logic_vector(31 downto 0); -- Sinal que sai do Mux_data
    signal Reg_Data1    :std_logic_vector(31 downto 0); -- Sinal que sai do banco de regs e vai para A e para o BEQ
    signal Reg_Data2    :std_logic_vector(31 downto 0); -- Sinal que sai do banco de reg e vai para B e para o BEQ
    signal RegA_OUT     :std_logic_vector(31 downto 0); -- Sinal que sai do Reg A e entra na ULA
    signal RegB_OUT     :std_logic_vector(31 downto 0); -- Sinal que sai do Reg B e entra na ULA e no Mux_mem
    signal ULA_Result   :std_logic_vector(31 downto 0); -- Sinal que sai do resultado da ULA e entra na ula_out  
    signal ULA_OUT_sign :std_logic_vector(31 downto 0); -- Sinal que sai da ula_out e entra no Mux_data
 ------------------- 
 --Decodificação do tipo das instruções:
 -- Campos comuns
    signal opcode       : std_logic_vector(3 downto 0);
    signal rs           : std_logic_vector(3 downto 0);
    signal rt           : std_logic_vector(3 downto 0);

-- Somente R-type
    signal rd           : std_logic_vector(3 downto 0);  

-- Endereço para LW, SW, BEQ
    signal addr_I       : std_logic_vector(9 downto 0);

-- Endereço para JUMP
    signal addr_J       : std_logic_vector(9 downto 0);

    signal write_reg    : std_logic_vector(3 downto 0);
    
----------------------------------------------
    signal Next_Pc_target       : std_Logic_vector(9 downto 0);
    signal beq_enable           :std_logic;
    signal verifica_beq_total   :std_logic;
    signal s_mem_data_in        : std_logic_vector(31 downto 0);

begin
    IR_OUT       <= IR;
    DR_OUT       <= DR;
    RegA_OUT     <= A;
    RegB_OUT     <= B;
    ULA_OUT_sign <= ULA_OUT;
    Opcode_out <= opcode;
    Zero_out <= zero_BEQ;
    s_mem_data_in <= RegB_OUT when Store_Source = '0' else ULA_Result;

    opcode <= IR(31 downto 28);
    rs     <= IR(27 downto 24);
    rt     <= IR(23 downto 20);
    rd     <= IR(19 downto 16);       -- Tipo R
    addr_I <= IR(19 downto 10);       -- Tipo I
    addr_J <= IR(27 downto 18);       -- Tipo J

process(opcode, rs, rt, rd)
begin
    case opcode is --Mux para decidir qual registrador passa o endereco para escrever

        -- Tipo R (ADD = 0000, AND = 0001, SUB = 0010)
        when "0000" | "0001" | "0010" =>
            write_reg <= rd;

        -- LW (0100)
        when "0100" =>
            write_reg <= rt;
            
        when others =>
            write_reg <= (others => '0'); --zera pro precaução
    end case;
end process;

Next_Pc_Target <= addr_I when fio_jump = '0'
    else addr_J;

beq_enable <= '1' when opcode = "0110" else '0';

verifica_beq_total  <= zero_BEQ and beq_enable;

process(clk, reset)
    begin
        if reset = '1' then
            PC_out <= (others => '0');
            IR <= (others => '0');
            A <= (others => '0');
            B <= (others => '0');
            ULA_OUT <= (others => '0');
            DR <= (others => '0');
            
        elsif rising_edge(clk) then  --Atuliza os registradores secundários, faz o caminho dos dados
        
            if Pc = '1'  then
                Pc_out <= Pc_in;
            end if;
        
            if Reg_inst = '1' then 
                IR <= MEM_OUT;
            end if;
            
            if Reg_data = '1' then  
                DR <= MEM_OUT;
            end if;
            
            if Reg_A = '1' then 
                A <= Reg_Data1;
            end if;
            
            if Reg_B = '1' then 
                B <= Reg_Data2;
            end if;
            
            if ULA_Write = '1' then 
                ULA_OUT <= ULA_Result;
            end if;    
         end if;    
end process;

Somador_pc : Somador_PC_4
    port map(
                somador_in => PC_out,
                somador_out => Pc_plus_4
            );
            
Ula_Instancia : ula
    port map(  
                a => RegA_OUT,
                b => RegB_OUT,
                ula_op => ULA_sign,
                result => ULA_Result
             );
             
Reg_File_Instancia : Reg_file 
    port map(
                clk              => clk,
                rst              => reset,
                escreve_reg      => Regs,
                leitura_rs       => IR(27 downto 24),
                leitura_rt       => IR(23 downto 20),
                endereco_escrita => write_reg, 
                escreve_dado     => Mux_Data_OUT,
                leitura_dado1    => Reg_Data1,
                leitura_dado2    => Reg_Data2
              );
            
Mux_Mem_Instancia : Mux_MEM
    port map(
              sel         => Mux_MEM_sign,
              reg_inst_in => addr_I,
              pc_in       => PC_out,
              reg_b_in    => RegB_OUT(9 downto 0),
              addr_out    => MEM_ADR
             ); 
    
Mux_Pc_Instancia : Mux_pc1 -- Instancia o mux do pc, criar mux para beq ou jump em questão da diferença do lugar dos bits que ele vai pegar
    port map(
              endereco_beq_jmp => Next_Pc_Target,
              pc_4             => PC_plus_4,
              verifica_jmp     => fio_jump,                  
              verifica_beq     => verifica_beq_total,
              pc_out           => PC_in
             );               
                
Mem_Instancia : memoria --TIRAR DUVIDA COM A DEBORA , COMO FAZER PRA QUANDO FOR UM STORE
    port map(
              clk              => clk,
              verifica_escrita => Mem,
              addr             => MEM_ADR,
              data_in          => s_mem_data_in,
              data_out         => MEM_OUT
             );            
            
Mux_data_Instancia : mux_data 
    port map(
              alu_in       => ULA_OUT_sign,
              mem_in       => DR_OUT,
              sel          => Mux_Data_sign,
              mux_data_out => Mux_Data_OUT
             );

Subtrator_Instancia : subtrator 
    port map(
              a             => regA_out,
              b             => regB_out,
              zero_beq      => zero_BEQ
             );
  

end architecture behavioral;    
      