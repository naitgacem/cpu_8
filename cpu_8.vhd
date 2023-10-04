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
            BUS_MUX_SEL : OUT unsigned(2 downto 0);
            CTRL_MAR_WE : OUT std_logic;
            CTRL_MEM_WE : OUT std_logic;
            CTRL_PC_WE  : OUT std_logic;
            CTRL_IR_WE  : OUT std_logic
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

    signal cpu_bus     : std_logic_vector(7 downto 0);
    signal IR          : std_logic_vector(7 downto 0);
    signal BUS_MUX_SEL : unsigned(2 downto 0);
    signal CTRL_MAR_WE : std_logic;
    signal CTRL_MEM_WE : std_logic;
    signal CTRL_IR_WE  : std_logic;
    signal CTRL_PC_WE  : std_logic;

    signal MEM_TO_BUS : std_logic_vector(7 downto 0);
    signal PC_TO_BUS  : std_logic_vector(7 downto 0);

    signal MAR_TO_MEM    : std_logic_vector(7 downto 0) := (others => '0');
    signal PC_INC_TO_BUS : std_logic_vector(7 downto 0);

    signal ADDRESS : natural := 0;

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

    ctrl_unit_inst : CTRL_UNIT
        port map(
            clk         => clk,
            reset       => reset,
            IR          => IR,
            BUS_MUX_SEL => BUS_MUX_SEL,
            CTRL_MAR_WE => CTRL_MAR_WE,
            CTRL_MEM_WE => CTRL_MEM_WE,
            CTRL_PC_WE  => CTRL_PC_WE,
            CTRL_IR_WE  => CTRL_IR_WE
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
            d0  => MEM_TO_BUS,
            d1  => PC_TO_BUS,
            d2  => PC_INC_TO_BUS,
            d3  => (others => '0'),
            d4  => (others => '0'),
            d5  => (others => '0'),
            d6  => (others => '0'),
            d7  => (others => '0'),
            y   => cpu_bus
        );

end arch;
