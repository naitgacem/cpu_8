library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_8 is

    port(
        clk   : in std_logic;
        reset : in std_logic
    );

end entity;

architecture arch of cpu_8 is

    component REG_8
        port(
            clk   : IN  std_logic;
            reset : IN  std_logic;
            WE    : IN  std_logic;
            D     : IN  std_logic_vector(7 downto 0);
            Q     : OUT std_logic_vector(7 downto 0)
        );
    end component;

    component ADDER_8
        port(
            D : IN  std_logic_vector(7 downto 0);
            Q : OUT std_logic_vector(7 downto 0)
        );
    end component;

    component CTRL_UNIT
        port(
            clk         : IN  std_logic;
            reset       : IN  std_logic;
            IR          : IN  std_logic_vector(7 downto 0);
            SCR         : IN  std_logic_vector(7 downto 0);
            BUS_MUX_SEL : OUT unsigned(2 downto 0);
            CTRL_MAR_WE : OUT std_logic;
            CTRL_MEM_WE : OUT std_logic;
            CTRL_PC_WE  : OUT std_logic;
            CTRL_IR_WE  : OUT std_logic;
            CTRL_B_WE   : OUT std_logic;
            CTRL_C_WE   : OUT std_logic;
            CTRL_ACC_WE : OUT std_logic;
            CTRL_TMP_WE : OUT std_logic;
            CTRL_SCR_WE : OUT std_logic;
            M1          : OUT std_logic
        );
    end component;

    component MEM_8
        generic(
            DATA_WIDTH : natural := 8;
            ADDR_WIDTH : natural := 8
        );
        port(
            clk  : in  std_logic;
            addr : in  natural range 0 to 2 ** ADDR_WIDTH - 1;
            data : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
            we   : in  std_logic := '1';
            q    : out std_logic_vector((DATA_WIDTH - 1) downto 0)
        );
    end component;

    component MUX_8_CH
        port(
            sel : in  unsigned(2 downto 0);
            d0  : in  std_logic_vector(7 downto 0);
            d1  : in  std_logic_vector(7 downto 0);
            d2  : in  std_logic_vector(7 downto 0);
            d3  : in  std_logic_vector(7 downto 0);
            d4  : in  std_logic_vector(7 downto 0);
            d5  : in  std_logic_vector(7 downto 0);
            d6  : in  std_logic_vector(7 downto 0);
            d7  : in  std_logic_vector(7 downto 0);
            y   : out std_logic_vector(7 downto 0)
        );
    end component;
    component ALU_8
        port(
            A      : IN  std_logic_vector(7 downto 0);
            B      : IN  std_logic_vector(7 downto 0);
            opcode : IN  std_logic_vector(3 downto 0);
            SCR    : OUT std_logic_vector(7 downto 0);
            Y      : OUT std_logic_vector(7 downto 0)
        );
    end component ALU_8;

    signal cpu_bus     : std_logic_vector(7 downto 0);
    signal IR          : std_logic_vector(7 downto 0);
    signal BUS_MUX_SEL : unsigned(2 downto 0);
    signal CTRL_MAR_WE : std_logic;
    signal CTRL_MEM_WE : std_logic;
    signal CTRL_IR_WE  : std_logic;
    signal CTRL_PC_WE  : std_logic;

    signal CTRL_B_WE   : std_logic;
    signal CTRL_C_WE   : std_logic;
    signal CTRL_ACC_WE : std_logic;
    signal CTRL_TMP_WE : std_logic;
    signal CTRL_SCR_WE : std_logic;

    signal MEM_TO_BUS : std_logic_vector(7 downto 0);
    signal PC_TO_BUS  : std_logic_vector(7 downto 0);

    signal MAR_TO_MEM    : std_logic_vector(7 downto 0) := (others => '0');
    signal PC_INC_TO_BUS : std_logic_vector(7 downto 0);
    signal C_REG_TO_BUS  : std_logic_vector(7 downto 0);
    signal B_REG_TO_BUS  : std_logic_vector(7 downto 0);
    signal ACC_TO_BUS    : std_logic_vector(7 downto 0);
    signal TMP_TO_BUS    : std_logic_vector(7 downto 0);
    signal ALU_TO_BUS    : std_logic_vector(7 downto 0);

    signal ADDRESS   : natural := 0;
    signal FLAGS_IN  : std_logic_vector(7 downto 0);
    signal FLAGS_OUT : std_logic_vector(7 downto 0);

    signal M1 : std_logic := '1';

begin

    MAR_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_MAR_WE,
            D     => cpu_bus,
            Q     => MAR_TO_MEM
        );

    ADDER_8_INST : ADDER_8
        port map(
            D => PC_TO_BUS,
            Q => PC_INC_TO_BUS
        );

    PC_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_PC_WE,
            D     => cpu_bus,
            Q     => PC_TO_BUS
        );

    IR_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_IR_WE,
            D     => cpu_bus,
            Q     => IR
        );
    SCR_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_SCR_WE,
            D     => FLAGS_IN,
            Q     => FLAGS_OUT
        );
    ctrl_unit_inst : CTRL_UNIT
        port map(
            clk         => clk,
            reset       => reset,
            IR          => IR,
            SCR         => FLAGS_OUT,
            BUS_MUX_SEL => BUS_MUX_SEL,
            CTRL_MAR_WE => CTRL_MAR_WE,
            CTRL_MEM_WE => CTRL_MEM_WE,
            CTRL_PC_WE  => CTRL_PC_WE,
            CTRL_IR_WE  => CTRL_IR_WE,
            CTRL_B_WE   => CTRL_B_WE,
            CTRL_C_WE   => CTRL_C_WE,
            CTRL_ACC_WE => CTRL_ACC_WE,
            CTRL_TMP_WE => CTRL_TMP_WE,
            CTRL_SCR_WE => CTRL_SCR_WE,
            M1          => M1
        );

    ADDRESS <= to_integer(unsigned(MAR_TO_MEM));

    mem_inst : MEM_8
        generic map(
            DATA_WIDTH => 8,
            ADDR_WIDTH => 8
        )
        port map(
            clk  => clk,
            addr => ADDRESS,
            data => cpu_bus,
            we   => CTRL_MEM_WE,
            q    => MEM_TO_BUS
        );

    mux_8_ch_inst : MUX_8_CH
        port map(
            sel => BUS_MUX_SEL,
            d0  => PC_TO_BUS,
            d1  => PC_INC_TO_BUS,
            d2  => MEM_TO_BUS,
            d3  => C_REG_TO_BUS,
            d4  => B_REG_TO_BUS,
            d5  => ACC_TO_BUS,
            d6  => TMP_TO_BUS,
            d7  => ALU_TO_BUS,
            y   => cpu_bus
        );
    B_reg_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_B_WE,
            D     => cpu_bus,
            Q     => B_REG_TO_BUS
        );
    C_reg_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_C_WE,
            D     => cpu_bus,
            Q     => C_REG_TO_BUS
        );
    ACC_reg_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_ACC_WE,
            D     => cpu_bus,
            Q     => ACC_TO_BUS
        );
    tmp_reg_inst_reg_inst : REG_8
        port map(
            clk   => clk,
            reset => reset,
            WE    => CTRL_TMP_WE,
            D     => cpu_bus,
            Q     => TMP_TO_BUS
        );
    alu_inst : ALU_8
        port map(
            A      => ACC_TO_BUS,
            B      => TMP_TO_BUS,
            opcode => IR(7 downto 4),
            SCR    => FLAGS_IN,
            Y      => ALU_TO_BUS
        );

end arch;
