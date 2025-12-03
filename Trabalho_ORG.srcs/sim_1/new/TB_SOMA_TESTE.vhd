library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_SOMA_TESTE is
end TB_SOMA_TESTE;

architecture sim of TB_SOMA_TESTE is

    ----------------------------------------------------------------
    -- COMPONENTES
    ----------------------------------------------------------------

    component data_path
        Port(
            clk             : in std_logic;
            reset           : in std_logic;
            Pc              : in std_logic;
            Mem             : in std_logic;
            Regs            : in std_logic;
            ULA_sign        : in std_logic_vector(1 downto 0);
            ULA_Write       : in std_logic;
            Reg_Inst        : in std_logic;
            Reg_Data        : in std_logic;     
            Reg_A           : in std_logic;
            Reg_B           : in std_logic;
            Mux_Data_sign   : in std_logic;
            Mux_PC_sign     : in std_logic_vector(1 downto 0);
            Mux_MEM_sign    : in std_logic_vector(1 downto 0);
            fio_jump        : in std_logic;
            Opcode_out      : out std_logic_vector(3 downto 0)
        );
    end component;

    component ControlUnit
        Port ( 
            clk             : in  std_logic;
            reset           : in  std_logic;
            Opcode          : in  std_logic_vector(3 downto 0); 
        
            Pc_write        : out std_logic;
            Mem_write       : out std_logic;
            Regs_write      : out std_logic;
            ULA_op          : out std_logic_vector(1 downto 0);
            Reg_Inst_write  : out std_logic;
            Reg_Data_write  : out std_logic;
            Mux_Data_sel    : out std_logic;
            Reg_A_write     : out std_logic;
            Reg_B_write     : out std_logic;
            Mux_PC_sel      : out std_logic_vector(1 downto 0);
            Mux_MEM_sel     : out std_logic_vector(1 downto 0);
            ULA_out_write   : out std_logic;
            fio_jump        : out std_logic
        );
    end component;

    component Memoria
        Port(
            clk              : in  std_logic;
            verifica_escrita : in  std_logic;
            addr             : in  std_logic_vector(9 downto 0);
            data_in          : in  std_logic_vector(31 downto 0);
            data_out         : out std_logic_vector(31 downto 0)
        );
    end component;

    ----------------------------------------------------------------
    -- SINAIS
    ----------------------------------------------------------------

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- Sinais da control unit para o datapath
    signal Pc_write_s       : std_logic;
    signal Mem_write_s      : std_logic;
    signal Regs_write_s     : std_logic;
    signal ULA_op_s         : std_logic_vector(1 downto 0);
    signal Reg_Inst_write_s : std_logic;
    signal Reg_Data_write_s : std_logic;
    signal Mux_Data_sel_s   : std_logic;
    signal Reg_A_write_s    : std_logic;
    signal Reg_B_write_s    : std_logic;
    signal Mux_PC_sel_s     : std_logic_vector(1 downto 0);
    signal Mux_MEM_sel_s    : std_logic_vector(1 downto 0);
    signal ULA_out_write_s  : std_logic;
    signal fio_jump_s       : std_logic;

    -- Sinal vindo do datapath para controle
    signal Opcode_s : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------
    -- CLOCK
    ----------------------------------------------------------------
    clk <= not clk after 5 ns;

    ----------------------------------------------------------------
    -- INSTÂNCIA DA CONTROL UNIT
    ----------------------------------------------------------------
    CU : ControlUnit
        port map(
            clk             => clk,
            reset           => reset,
            Opcode          => Opcode_s,
            Pc_write        => Pc_write_s,
            Mem_write       => Mem_write_s,
            Regs_write      => Regs_write_s,
            ULA_op          => ULA_op_s,
            Reg_Inst_write  => Reg_Inst_write_s,
            Reg_Data_write  => Reg_Data_write_s,
            Mux_Data_sel    => Mux_Data_sel_s,
            Reg_A_write     => Reg_A_write_s,
            Reg_B_write     => Reg_B_write_s,
            Mux_PC_sel      => Mux_PC_sel_s,
            Mux_MEM_sel     => Mux_MEM_sel_s,
            ULA_out_write   => ULA_out_write_s,
            fio_jump        => fio_jump_s
        );

    ----------------------------------------------------------------
    -- INSTÂNCIA DO DATAPATH
    ----------------------------------------------------------------
    DP : data_path
        port map(
            clk           => clk,
            reset         => reset,
            Pc            => Pc_write_s,
            Mem           => Mem_write_s,
            Regs          => Regs_write_s,
            ULA_sign      => ULA_op_s,
            ULA_Write     => ULA_out_write_s,
            Reg_Inst      => Reg_Inst_write_s,
            Reg_Data      => Reg_Data_write_s,
            Reg_A         => Reg_A_write_s,
            Reg_B         => Reg_B_write_s,
            Mux_Data_sign => Mux_Data_sel_s,
            Mux_PC_sign   => Mux_PC_sel_s,
            Mux_MEM_sign  => Mux_MEM_sel_s,
            fio_jump      => fio_jump_s,
            Opcode_out    => Opcode_s
        );


    ----------------------------------------------------------------
    -- ESTÍMULOS
    ----------------------------------------------------------------
    process
    begin
        -- RESET INICIAL
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

        -- deixa rodar a FSM
        wait for 500 ns;

        wait;
    end process;

end sim;
