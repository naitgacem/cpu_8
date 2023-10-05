library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_unit_tb is
end entity ctrl_unit_tb;

architecture testbench of ctrl_unit_tb is
    component CTRL_UNIT
        port(
            clk         : IN  std_logic;
            reset       : IN  std_logic;
            IR          : IN  unsigned(7 downto 0);
            BUS_MUX_SEL : OUT unsigned(2 downto 0);
            CTRL_MAR_WE : OUT std_logic;
            CTRL_MEM_WE : OUT std_logic;
            CTRL_PC_WE  : OUT std_logic;
            CTRL_IR_WE  : OUT std_logic
        );
    end component CTRL_UNIT;
    signal clk         : std_logic;
    signal reset       : std_logic;
    signal IR          : unsigned(7 downto 0);
    signal BUS_MUX_SEL : unsigned(2 downto 0);
    signal CTRL_MAR_WE : std_logic;
    signal CTRL_MEM_WE : std_logic;
    signal CTRL_PC_WE  : std_logic;
    signal CTRL_IR_WE  : std_logic;
begin
    dut : CTRL_UNIT
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
    clk_process : process
    begin
        while now < 1000 ns loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    reset_process : process
    begin
        reset <= '0';
        wait for 10 ns;
        reset <= '1';
        wait;
    end process;
end architecture testbench;

