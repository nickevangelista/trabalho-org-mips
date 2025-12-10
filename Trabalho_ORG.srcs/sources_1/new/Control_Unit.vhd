library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ControlUnit is
    Port ( 
        clk             : in  std_logic;
        reset           : in  std_logic;
        
        Zero            : in  std_logic;                        -- Flag do BEQ
        Opcode          : in  std_logic_vector(3 downto 0); 
        
        -- Saídas para o Data Path 
        Pc_write        : out std_logic;                        -- controle do PC
        Mem_write       : out std_logic;                        -- controle da memória                       
        Regs_write      : out std_logic;                        -- controle do banco de regs
        ULA_op          : out std_logic_vector(1 downto 0);     -- ULA (00-add, 10-sub, 01-and)
        Reg_Inst_write  : out std_logic;                        -- IR
        Reg_Data_write  : out std_logic;                        -- DR
        Mux_Data_sel    : out std_logic ;                       -- mux data (1 - ULA_out, 0 para mem_data)
        Reg_A_write     : out std_logic;
        Reg_B_write     : out std_logic;
        Mux_PC_sel      : out std_logic_vector(1 downto 0);     -- Mux PC
        Mux_MEM_sel     : out std_logic_vector(1 downto 0);     -- Mux MEM
        ULA_out_write   : out std_logic;                        -- Controle do registrador de saída da ULA
        Store_Source_sel : out std_logic;
        fio_jump        : out std_Logic
    );
end ControlUnit;

architecture Behavioral of ControlUnit is

    type state_type is (
        IDLE,       
        IF_STATE,   
        ID_STATE,   
        REGS_STATE, -- Leitura de Regs/Decisão
        ADD_STATE,  
        SUB_STATE,  
        AND_STATE,  
        WB_STATE,   -- WB 
        LOAD10,     -- calcula endereco do LOAD
        LOAD11,     -- leitura do dado na memória
        LOAD12,     -- WB do load
        STORE13,    
        BEQ4,       
        JUMP5,
        SADD_STATE       
    );
    
    signal current_state, next_state : state_type;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, Opcode)
    begin
       
        Pc_write       <= '0';
        Mem_write      <= '0';
        Regs_write     <= '0';
        ULA_op         <= "00";
        Reg_Inst_write <= '0';
        Reg_Data_write <= '0';
        Mux_Data_sel   <= '0';
        Reg_A_write    <= '0';
        Reg_B_write    <= '0';
        Mux_PC_sel     <= "00";
        Mux_MEM_sel    <= "00";
        ULA_out_write  <= '0';

        fio_jump       <= '0';
        Store_Source_sel <= '0';

        case current_state is
            
            when IDLE =>
                next_state <= IF_STATE;

            when IF_STATE =>
                Pc_write       <= '1';  
                Mem_write      <= '0';  
                Reg_Inst_write <= '0';  
                Mux_MEM_sel    <= "01"; 
                next_state     <= ID_STATE;

            when ID_STATE =>
                Mem_write      <= '0'; 
                Reg_Inst_write <= '1'; 
                Reg_Data_write <= '1';
                next_state <= REGS_STATE;
                Pc_write <= '0';

            when REGS_STATE =>
                Regs_write <= '0';
                Reg_Inst_write <= '0';
                Reg_Data_write <= '0';
                Mem_write <= '0';
                Reg_A_write    <= '1';
                Reg_B_write    <= '1';
                
                case Opcode is
                    when "0000" => next_state <= ADD_STATE;    -- Add
                    when "0010" => next_state <= SUB_STATE;    -- Sub
                    when "0001" => next_state <= AND_STATE;    -- And
                    when "0100" => next_state <= LOAD10;       -- Load 
                    when "0101" => next_state <= STORE13;      -- Store
                    when "0011" => next_state <= SADD_STATE;   -- SADD
                    -- Beq (X11X) 
                    when "0110" | "0111" | "1110" | "1111" => next_state <= BEQ4; 
                    -- Jump (1XXX) 
                    when "1000" | "1001" | "1010" | "1011" | "1100" | "1101" => next_state <= JUMP5;
                    when others => next_state <= IF_STATE; 
                end case;

            when ADD_STATE =>
                Reg_A_write   <= '0';
                Reg_B_write   <= '0';
                ULA_op        <= "00";
                ULA_out_write <= '1'; 
                next_state    <= WB_STATE;

            when SUB_STATE =>
                Reg_A_write   <= '1';
                Reg_B_write   <= '1';
                ULA_op        <= "10";
                ULA_out_write <= '1';
                next_state    <= WB_STATE;

            when AND_STATE =>
                Reg_A_write   <= '1';
                Reg_B_write   <= '1';
                ULA_op        <= "01"; 
                ULA_out_write <= '1';
                next_state    <= WB_STATE;
                
            when WB_STATE =>
                Regs_write   <= '1';      -- Escreve no banco
                Mux_Data_sel <= '1';      -- Seleciona a ULA para escrever de volta
                next_state   <= IF_STATE;


            when LOAD10 =>
                Mem_write    <= '0';      
                Mux_MEM_sel  <= "00";
                next_state   <= LOAD11;

            when LOAD11 =>
                Reg_Data_write <= '1';    -- Salva valor lido no DR
                Mux_Data_sel   <= '1'; 
                next_state     <= LOAD12;

            when LOAD12 =>
                Regs_write   <= '1';       -- Escreve no destino
                next_state   <= IF_STATE;

            when STORE13 =>
                Mem_write    <= '1';  
                Mux_MEM_sel  <= "00";       -- Seleciona endereço correto
                next_state   <= IF_STATE;

            when BEQ4 => 
                ULA_op <= "10"; 
                if (Zero = '1') then
                    Pc_write     <= '1';  -- Habilita a escrita no PC AGORA
                    Mux_PC_sel   <= "01"; 
                else
                    Pc_write     <= '0';
                    Mux_PC_sel   <= "00";
                end if;
                next_state   <= IF_STATE;
                
            when JUMP5 =>
                Pc_write     <= '1';
                Mux_PC_sel   <= "11";     -- Seleciona endereço de salto
                fio_jump     <= '1';
                next_state   <= IF_STATE;
            
            when SADD_STATE =>
                ULA_op <= "00"; 
                Mux_MEM_sel <= "00"; 
                Mem_write <= '1';
                Store_Source_sel <= '1'; 
                next_state <= IF_STATE;
            when others =>
                next_state <= IDLE;
        end case;
    end process;

end Behavioral;