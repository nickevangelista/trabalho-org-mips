library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_id_stage is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- entrada: PC atual
        pc_in      : in  std_logic_vector(15 downto 0);

        -- sa?das : endere?o de jump direto | endere?o de branch(6bits) | instru??o buscada 
        inst_out     : out std_logic_vector(15 downto 0); -- vai para o registrador de instru??o
        jump_target  : out std_logic_vector(15 downto 0); -- vai para o mux do pc (usada tanto em jmp quanto em compara??o)
        offset_addr  : out std_logic_vector(15 downto 0);  -- vai para o mux do regB (usado para load/store)
        opcode_uc    : out std_logic_vector(3 downto 0)  -- vai para a unidade de controle


    );
end entity;

architecture rtl of if_id_stage is
    --------------------------------------------------------------------------------------------------------------------------------------
    -- Mem?ria de instru??o (ROM s?ncrona)
    --------------------------------------------------------------------------------------------------------------------------------------
    type rom_t is array (0 to 4095) of std_logic_vector(15 downto 0);
    constant ROM : rom_t := (
        0 => x"0000", -- binario de instru??es de exemplo
        1 => x"0000", 
        others => (others => '0')
    );

    signal instr_bits : std_logic_vector(15 downto 0);
    signal opcode     : std_logic_vector(3 downto 0);

begin
    --------------------------------------------------------------------------------------------------------------------------------------
    -- ROM s?ncrona (1 ciclo de lat?ncia)
    --------------------------------------------------------------------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            instr_bits <= ROM(to_integer(unsigned(pc_in))); --Recebe o endere?o da instru??o(entra 16 bits, mas s? usa 12 bits)
            opcode    <= ROM(to_integer(unsigned(pc_in)))(15 downto 12); --Extrai o opcode dos 4 bits mais significativos
        end if;
    end process;
    --------------------------------------------------------------------------------------------------------------------------------------
    -- IF/ID register
    --------------------------------------------------------------------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            case opcode is
                when "0110" =>
                    -- Instru??o JUMP
                    inst_out     <= (others => '0');
                    jump_target  <= "0000" & instr_bits(11 downto 0); 
                    offset_addr  <= (others => '0');
                    opcode_uc    <= opcode;
                when "0111" | "1000" | "1001" =>
                    -- Instru??o JEQ, JBG, JLR 
                    inst_out     <= instr_bits;
                    jump_target  <= (others => '0');
                    offset_addr  <= "0000" & instr_bits(11 downto 0);
                    opcode_uc    <= opcode;
                when "0100" | "0101" =>
                    -- Instru??o LOAD, STORE
                    inst_out     <= instr_bits;
                    jump_target  <= (others => '0');
                    offset_addr  <= "0000000000" & instr_bits(5 downto 0);
                    opcode_uc    <= opcode;
                when others =>
                    -- Outras instru??es
                    inst_out     <= instr_bits;
                    jump_target  <= (others => '0');
                    offset_addr  <= (others => '0');
            end case;
        end if;
    end process;
end architecture;