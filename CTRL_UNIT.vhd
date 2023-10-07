library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity CTRL_UNIT is

    port(
        clk         : IN  std_logic;
        reset       : IN  std_logic;
        IR          : IN  std_logic_vector(7 downto 0);
        BUS_MUX_SEL : OUT unsigned(2 downto 0);
        CTRL_MAR_WE : OUT std_logic;
        CTRL_MEM_WE : OUT std_logic;
        CTRL_PC_WE  : OUT std_logic;
        CTRL_IR_WE  : OUT std_logic;
        CTRL_B_WE   : OUT std_logic;
        CTRL_C_WE   : OUT std_logic;
        CTRL_ACC_WE : OUT std_logic;
        CTRL_TMP_WE : OUT std_logic;
        M1          : out std_logic
    );

end entity;

architecture arch of CTRL_UNIT is

    TYPE Tstate IS (FETCH_CYCLE, DECODE_CYCLE, EXECUTE_CYCLE);
    SIGNAL state      : Tstate := FETCH_CYCLE;
    SIGNAL next_state : Tstate := FETCH_CYCLE;

    constant PC_OUT     : natural                      := 0;
    constant PC_INC_OUT : natural                      := 1;
    constant MEM_OUT    : natural                      := 2;
    constant C_REG_OUT  : natural                      := 3;
    constant B_REG_OUT  : natural                      := 4;
    constant ACC_OUT    : natural                      := 5;
    constant TMP_OUT    : natural                      := 6;
    constant ALU_OUT    : natural                      := 7;
    signal opcode       : std_logic_vector(3 downto 0);
    constant IMMEDIATE  : std_logic_vector(1 downto 0) := "01";
    constant REG        : std_logic_vector(1 downto 0) := "10";

    TYPE stage is (s1, s2, s3, s4, s5, s6, s7);
    signal T_COUNT : stage;
    signal ticks   : natural := 0;

    constant LOAD  : std_logic_vector(3 downto 0) := "0000";
    constant STORE : std_logic_vector(3 downto 0) := "0001";
    constant ADD   : std_logic_vector(3 downto 0) := "0010";

    signal fetch_start : std_logic := '1';

begin

    opcode <= IR(7 downto 4);
    M1     <= fetch_start;

    process(clk, reset)
        variable mode : std_logic_vector(1 downto 0) := "00";
        variable RR   : std_logic_vector(1 downto 0) := "00";
    begin
        IF reset = '0' THEN
            state   <= FETCH_CYCLE;
            T_COUNT <= s1;
        ELSIF rising_edge(clk) THEN
            ticks       <= ticks + 1;
            BUS_MUX_SEL <= (others => '0');
            CTRL_MAR_WE <= '1';
            CTRL_MEM_WE <= '0';
            CTRL_IR_WE  <= '1';
            CTRL_PC_WE  <= '1';
            CTRL_B_WE   <= '1';
            CTRL_C_WE   <= '1';
            CTRL_ACC_WE <= '1';
            CTRL_TMP_WE <= '1';
            fetch_start <= '1';
            CASE state IS
                WHEN FETCH_CYCLE =>
                    fetch_start <= '0';
                    case T_COUNT is
                        when s1 =>
                            BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                            CTRL_MAR_WE <= '0';
                            T_COUNT     <= s2;
                        when s2 =>
                            T_COUNT <= s3;
                        WHEN s3 =>
                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                            CTRL_IR_WE  <= '0';
                            T_COUNT     <= s4;
                        when others =>
                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                            CTRL_PC_WE  <= '0';
                            T_COUNT     <= s1;
                            next_state  <= DECODE_CYCLE;
                    end case;
                WHEN DECODE_CYCLE =>
                    case opcode is
                        when LOAD =>
                            mode := IR(3 downto 2);
                            RR   := IR(1 downto 0);
                            case mode is
                                when IMMEDIATE =>
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 => -- memory being addressed
                                            T_COUNT <= s3;
                                        WHEN s3 =>
                                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                            case RR is
                                                when "00" =>
                                                    CTRL_B_WE <= '0';
                                                when "01" =>
                                                    CTRL_C_WE <= '0';
                                                when "10" =>
                                                    CTRL_ACC_WE <= '0';
                                                when others =>
                                            end case;
                                            T_COUNT     <= s4;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                                when others => -- load from memory
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 =>
                                            T_COUNT <= s3;
                                        WHEN s3 =>
                                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s4;
                                        when s4 =>
                                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s5;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                            case RR is
                                                when "00" =>
                                                    CTRL_B_WE <= '0';
                                                when "01" =>
                                                    CTRL_C_WE <= '0';
                                                when "10" =>
                                                    CTRL_ACC_WE <= '0';
                                                when others =>
                                                    report "illegal" severity NOTE;
                                            end case;
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                            end case;
                        when STORE =>
                            mode := IR(3 downto 2);
                            RR   := IR(1 downto 0);
                            case mode is
                                when REG =>
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 => -- memory being addressed
                                            T_COUNT <= s3;
                                        WHEN s3 =>
                                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                            CTRL_TMP_WE <= '0';
                                            T_COUNT     <= s4;
                                        when s4 =>
                                            case RR is
                                                when "00" =>
                                                    BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                when "01" =>
                                                    BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                when "10" =>
                                                    BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                when others =>
                                                    report "illegal" severity NOTE;
                                            end case;
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s5;
                                        when s5 =>
                                            T_COUNT <= s6;
                                        when s6 =>
                                            BUS_MUX_SEL <= to_unsigned(TMP_OUT, BUS_MUX_SEL'length);
                                            CTRL_MEM_WE <= '1';
                                            T_COUNT     <= s7;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                                when others => -- store RR content into memory
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 =>
                                            T_COUNT <= s3;
                                        WHEN s3 =>
                                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s4;
                                        when s4 =>
                                            case RR is
                                                when "00" =>
                                                    BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                when "01" =>
                                                    BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                when "10" =>
                                                    BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                when others =>
                                                    report "illegal" severity NOTE;
                                            end case;
                                            BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                            CTRL_MEM_WE <= '1';
                                            T_COUNT     <= s5;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                            end case;

                        when others =>
                            next_state <= EXECUTE_CYCLE;
                    end case;

                WHEN EXECUTE_CYCLE =>
                    next_state <= FETCH_CYCLE;
            END CASE;
        END IF;
        state <= next_state;
    end process;

end arch;

