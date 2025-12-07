library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TopLevel is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC
    );
end TopLevel;

architecture Behavioral of TopLevel is

    -- Sinais que saem da UC e entram no datapath
    signal s_pc_write       : std_logic;
    signal s_mem_write      : std_logic;
    signal s_regs_write     : std_logic;
    signal s_ula_op         : std_logic_vector(1 downto 0);
    signal s_reg_inst_write : std_logic;
    signal s_reg_data_write : std_logic;
    signal s_mux_data_sel   : std_logic;
    signal s_reg_a_write    : std_logic;
    signal s_reg_b_write    : std_logic;
    signal s_mux_pc_sel     : std_logic_vector(1 downto 0);
    signal s_mux_mem_sel    : std_logic_vector(1 downto 0);
    signal s_ula_out_write  : std_logic;
    signal s_fio_jump       : std_logic;
    signal s_store_source   : std_logic;

    -- Sinal que sai do datapath e entra na UC
    signal s_opcode         : std_logic_vector(3 downto 0);
    signal s_zero_flag      : std_logic;
    

begin

    datapath_inst : entity work.data_path
        port map (
            clk             => clk,
            reset           => reset,
            
            -- Sinais de entrada da UC
            Pc              => s_pc_write,
            Mem             => s_mem_write,
            Regs            => s_regs_write,
            ULA_sign        => s_ula_op,
            ULA_Write       => s_ula_out_write,
            Reg_Inst        => s_reg_inst_write,
            Reg_Data        => s_reg_data_write,
            Mux_Data_sign   => s_mux_data_sel,
            Reg_A           => s_reg_a_write,
            Reg_B           => s_reg_b_write,
            Mux_PC_sign     => s_mux_pc_sel,
            Mux_MEM_sign    => s_mux_mem_sel,
            Zero_out        => s_zero_flag,
            fio_jump        => s_fio_jump,
            Store_Source    => s_store_source,
            
            -- Sinal de sáida para a UC
            Opcode_out      => s_opcode
           
        );

    control_inst : entity work.ControlUnit
        port map (
            clk             => clk,
            reset           => reset,
            
            --Entrada
            Opcode          => s_opcode,
            Zero            => s_zero_flag,
            
            -- Saídas 
            Pc_write         => s_pc_write,
            Mem_write        => s_mem_write,
            Regs_write       => s_regs_write,
            ULA_op           => s_ula_op,
            Reg_Inst_write   => s_reg_inst_write,
            Reg_Data_write   => s_reg_data_write,
            Mux_Data_sel     => s_mux_data_sel,
            Reg_A_write      => s_reg_a_write,
            Reg_B_write      => s_reg_b_write,
            Mux_PC_sel       => s_mux_pc_sel,
            Mux_MEM_sel      => s_mux_mem_sel,
            ULA_out_write    => s_ula_out_write,
            Store_Source_sel => s_store_source,
            fio_jump         => s_fio_jump
        );

end Behavioral;