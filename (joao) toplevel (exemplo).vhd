library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
    port (
        clk   : in std_logic;
        rst   : in std_logic
        -- aqui futuramente entram sinais da UC (alu_sel, we?s, is_jump, etc.)
    );
end entity;

architecture structural of datapath is

    -- sinais do PC
    signal pc_reg, pc_next, pc_plus1 : std_logic_vector(15 downto 0);

    -- instru??o buscada
    signal inst_out     : std_logic_vector(15 downto 0);
    signal jump_target  : std_logic_vector(15 downto 0);
    signal offset_addr  : std_logic_vector(15 downto 0);
    signal opcode_uc    : std_logic_vector(3 downto 0);

    -- banco de registradores
    signal rs_addr, rt_addr, rd_addr : std_logic_vector(2 downto 0);
    signal rs_data, rt_data, rd_data : std_logic_vector(15 downto 0);

    -- registradores tempor?rios
    signal A, B, C, ULAout : std_logic_vector(15 downto 0);

    -- ULA
    signal alu_result : std_logic_vector(15 downto 0);
    signal alu_zero, alu_greater, alu_less : std_logic;

    -- mem?ria de dados
    signal mem_data_out : std_logic_vector(15 downto 0);

    -- sinais de controle (futuros: vir?o da UC)
    signal we_A, we_B, we_C, we_ULAout : std_logic := '0';
    signal we_regfile : std_logic := '0';
    signal we_mem     : std_logic := '0';
    signal alu_sel    : std_logic_vector(2 downto 0) := (others => '0');
    signal is_jump, is_branch : std_logic := '0';
    signal flag_sel   : std_logic_vector(1 downto 0) := "00"; -- UC escolhe qual flag usar
    signal branch_taken : std_logic;

begin
    ----------------------------------------------------------------------
    -- PC + somador + mux
    ----------------------------------------------------------------------
    pc_reg_inst: entity work.pc
        port map (
            clk => clk,
            rst => rst,
            d   => pc_next,
            q   => pc_reg
        );

    pc_adder: entity work.somador
        port map (
            somador_in  => pc_reg,
            somador_out => pc_plus1
        );

    pc_mux_inst: entity work.pc_mux
        port map (
            pc_plus1    => pc_plus1,
            jump_target => jump_target,
            branch_addr => offset_addr,
            flag        => branch_taken,
            is_jump     => is_jump,
            is_branch   => is_branch,
            pc_next     => pc_next
        );

    ----------------------------------------------------------------------
    -- Mem?ria de instru??es (IF/ID)
    ----------------------------------------------------------------------
    ifid: entity work.if_id_stage
        port map (
            clk         => clk,
            rst         => rst,
            pc_in       => pc_reg,
            inst_out    => inst_out,
            jump_target => jump_target,
            offset_addr => offset_addr,
            opcode_uc   => opcode_uc
        );

    ----------------------------------------------------------------------
    -- Banco de registradores
    ----------------------------------------------------------------------
    regfile: entity work.reg_file
        port map (
            clk => clk,
            rst => rst,
            rs_addr => rs_addr,
            rt_addr => rt_addr,
            rd_addr => rd_addr,
            rd_data_in  => rd_data,
            rs_data_out => rs_data,
            rt_data_out => rt_data,
            we => we_regfile
        );

    ----------------------------------------------------------------------
    -- Registradores tempor?rios A, B, C, ULAout
    ----------------------------------------------------------------------
    regA: entity work.temp_reg
        generic map (N => 16)
        port map (clk => clk, rst => rst, we => we_A, d => rs_data, q => A);

    regB: entity work.temp_reg
        generic map (N => 16)
        port map (clk => clk, rst => rst, we => we_B, d => rt_data, q => B);

    regC: entity work.temp_reg
        generic map (N => 16)
        port map (clk => clk, rst => rst, we => we_C, d => rt_data, q => C);

    regULA: entity work.temp_reg
        generic map (N => 16)
        port map (clk => clk, rst => rst, we => we_ULAout, d => alu_result, q => ULAout);

    ----------------------------------------------------------------------
    -- ULA
    ----------------------------------------------------------------------
    alu_inst: entity work.alu
        port map (
            a      => A,
            b      => B,
            sel    => alu_sel,
            result => alu_result,
            zero    => alu_zero,
            greater => alu_greater,
            less    => alu_less
        );

    -- multiplexador interno para escolher qual flag usar no PC
    branch_taken <= alu_zero when flag_sel = "00" else
                    alu_greater when flag_sel = "01" else
                    alu_less when flag_sel = "10" else
                    '0';

    ----------------------------------------------------------------------
    -- Mem?ria de dados
    ----------------------------------------------------------------------
    dmem: entity work.data_memory
        port map (
            clk   => clk,
            rst   => rst,
            addr  => B(9 downto 0),  -- endere?o calculado
            wdata => C,              -- dado a salvar (SW)
            rdata => mem_data_out,   -- dado lido (LW)
            we    => we_mem
        );

    -- Exemplo de caminho de escrita de LOAD (a UC decide)
    rd_data <= mem_data_out;

end architecture;