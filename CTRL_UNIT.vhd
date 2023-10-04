library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CTRL_UNIT is

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

end entity;

architecture arch of CTRL_UNIT is

    TYPE Tstate IS (FETCH_CYCLE_AD, FETCH_CYCLE_IR, FETCH_CYCLE_INC_PC, DECODE_CYCLE, EXECUTE_CYCLE);
    SIGNAL state      : Tstate;
    SIGNAL next_state : Tstate;

    constant PC_OUT     : natural := 0;
    constant PC_INC_OUT : natural := 1;
    constant MEM_OUT    : natural := 2;

begin
    process(clk, reset)
    begin
        IF reset = '0' THEN
            state <= FETCH_CYCLE_AD;
        ELSIF rising_edge(clk) THEN
            state <= next_state;
        END IF;
    end process;

    PROCESS(state)
    BEGIN
        BUS_MUX_SEL <= (others => '0');
        CTRL_MAR_WE <= '1';
        CTRL_MEM_WE <= '1';
        CTRL_IR_WE  <= '1';
        CTRL_PC_WE  <= '1';
        CASE state IS
            WHEN FETCH_CYCLE_AD =>
                BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                report "we have done it";

                CTRL_MAR_WE <= '0';
                CTRL_MEM_WE <= '0';
                next_state  <= FETCH_CYCLE_IR;
            WHEN FETCH_CYCLE_IR =>
                BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                CTRL_IR_WE  <= '0';
                next_state  <= FETCH_CYCLE_INC_PC;
            when FETCH_CYCLE_INC_PC =>
                BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                CTRL_PC_WE  <= '0';
                next_state  <= DECODE_CYCLE;
            WHEN DECODE_CYCLE =>
                CTRL_IR_WE <= '1';
                next_state <= EXECUTE_CYCLE;
            WHEN EXECUTE_CYCLE =>
                next_state <= FETCH_CYCLE_AD;
            WHEN OTHERS =>
                next_state <= FETCH_CYCLE_AD;
        END CASE;
    END PROCESS;

end arch;
