library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity CTRL_UNIT is

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
        M1          : out std_logic
    );

end entity;

architecture arch of CTRL_UNIT is

    TYPE Tstate IS (FETCH_CYCLE, DECODE_CYCLE, EXECUTE_CYCLE);
    SIGNAL state      : Tstate := FETCH_CYCLE;
    SIGNAL next_state : Tstate := FETCH_CYCLE;

    constant PC_OUT     : natural := 0;
    constant PC_INC_OUT : natural := 1;
    constant MEM_OUT    : natural := 2;
    constant C_REG_OUT  : natural := 3;
    constant B_REG_OUT  : natural := 4;
    constant ACC_OUT    : natural := 5;
    constant TMP_OUT    : natural := 6;
    constant ALU_OUT    : natural := 7;

    signal opcode : std_logic_vector(3 downto 0);

    constant IMMEDIATE : std_logic_vector(1 downto 0) := "01";
    constant REG       : std_logic_vector(1 downto 0) := "10";

    TYPE stage is (s1, s2, s3, s4, s5, s6, s7);
    signal T_COUNT : stage;

    constant LOAD  : std_logic_vector(3 downto 0) := "0000";
    constant STORE : std_logic_vector(3 downto 0) := "0001";
    constant ADD   : std_logic_vector(3 downto 0) := "0010";

    constant ADC            : std_logic_vector(3 downto 0) := "0100";
    constant SUBTRACT       : std_logic_vector(3 downto 0) := "0011";
    constant COMPARE        : std_logic_vector(3 downto 0) := "0101";
    constant INCREMENT      : std_logic_vector(3 downto 0) := "0110";
    constant DECREMENT      : std_logic_vector(3 downto 0) := "0111";
    constant AND_OP         : std_logic_vector(3 downto 0) := "1000";
    constant OR_OP          : std_logic_vector(3 downto 0) := "1001";
    constant XOR_OP         : std_logic_vector(3 downto 0) := "1010";
    constant SHIFT_LEFT_OP  : std_logic_vector(3 downto 0) := "1011";
    constant SHIFT_RIGHT_OP : std_logic_vector(3 downto 0) := "1100";
    constant JUMP           : std_logic_vector(3 downto 0) := "1101";
    constant COND_JUMP      : std_logic_vector(3 downto 0) := "1110";
    constant HALT           : std_logic_vector(3 downto 0) := "1111";

    constant REGISTER_ACC : std_logic_vector(1 downto 0) := "10";
    constant REGISTER_B   : std_logic_vector(1 downto 0) := "00";
    constant REGISTER_C   : std_logic_vector(1 downto 0) := "01";

    constant IF_LARGER      : std_logic_vector(2 downto 0) := "000";
    constant IF_LESS        : std_logic_vector(2 downto 0) := "001";
    constant IF_EQUAL       : std_logic_vector(2 downto 0) := "010";
    constant IF_NOT_EQUAL   : std_logic_vector(2 downto 0) := "011";
    constant IF_CARRY       : std_logic_vector(2 downto 0) := "100";
    constant IF_NO_CARRY    : std_logic_vector(2 downto 0) := "101";
    constant IF_OVERFLOW    : std_logic_vector(2 downto 0) := "110";
    constant IF_NO_OVERFLOW : std_logic_vector(2 downto 0) := "111";

    constant carry_flag    : natural := 0;
    constant zero_flag     : natural := 1;
    constant overflow_flag : natural := 2;
    constant sign_flag     : natural := 3;

    signal fetch_start : std_logic := '1';

begin

    opcode <= IR(7 downto 4);
    M1     <= fetch_start;

    process(clk, reset)
        variable mode : std_logic_vector(1 downto 0) := "00";
        variable RR   : std_logic_vector(1 downto 0) := "00";
        variable R1   : std_logic_vector(1 downto 0) := "00";
        variable R2   : std_logic_vector(1 downto 0) := "00";
        variable CC   : std_logic_vector(2 downto 0) := "000";

    begin
        IF reset = '0' THEN
            state   <= FETCH_CYCLE;
            T_COUNT <= s1;
        ELSIF rising_edge(clk) THEN
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
                        when ADD | SUBTRACT | ADC | COMPARE | AND_OP | OR_OP | XOR_OP =>
                            R1 := IR(3 downto 2);
                            R2 := IR(1 downto 0);
                            case (R1 & R2) is
                                when "0001" | "0100" => -- B and C
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                            CTRL_TMP_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 =>
                                            BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                            CTRL_ACC_WE <= '0';
                                            T_COUNT     <= s3;
                                        WHEN s3 =>
                                            T_COUNT <= s4;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(ALU_OUT, BUS_MUX_SEL'length);
                                            CTRL_ACC_WE <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                                when "1000" | "0010" => -- acc with b 
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                            CTRL_TMP_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 =>
                                            T_COUNT <= s3;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(ALU_OUT, BUS_MUX_SEL'length);
                                            CTRL_ACC_WE <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                                when "1001" | "0110" => -- acc with c   
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                            CTRL_TMP_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 =>
                                            T_COUNT <= s3;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(ALU_OUT, BUS_MUX_SEL'length);
                                            CTRL_ACC_WE <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                                when others =>
                                    report "illegal" severity NOTE;
                            end case;
                        when INCREMENT  | DECREMENT | SHIFT_LEFT_OP | SHIFT_RIGHT_OP =>
                            RR := IR(1 downto 0);
                            case T_COUNT IS
                                when s1 =>
                                    case RR is
                                        when REGISTER_ACC =>
                                            BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                        when REGISTER_B =>
                                            BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                        when REGISTER_C =>
                                            BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                        when others =>
                                            report "" severity note;
                                    end case;
                                    CTRL_TMP_WE <= '0';
                                    T_COUNT     <= s2;
                                when s2 =>
                                    T_COUNT <= s3;
                                when others =>
                                    case RR is
                                        when REGISTER_ACC =>
                                            CTRL_ACC_WE <= '0';
                                        when REGISTER_B =>
                                            CTRL_B_WE <= '0';
                                        when REGISTER_C =>
                                            CTRL_C_WE <= '0';
                                        when others =>
                                            report "" severity note;
                                    end case;
                                    BUS_MUX_SEL <= to_unsigned(ALU_OUT, BUS_MUX_SEL'length);
                                    T_COUNT     <= s1;
                                    next_state  <= EXECUTE_CYCLE;
                            end case;
                        when JUMP =>
                            mode := IR(3 downto 2);
                            RR   := IR(1 downto 0);
                            case mode IS
                                when IMMEDIATE =>
                                    case T_COUNT is
                                        when s1 =>
                                            BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                            CTRL_MAR_WE <= '0';
                                            T_COUNT     <= s2;
                                        when s2 =>
                                            T_COUNT <= s3;
                                        WHEN s3 =>
                                            BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s4;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                                when others =>
                                    case T_COUNT is
                                        when s1 =>
                                            case RR is
                                                when REGISTER_B =>
                                                    BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                when REGISTER_C =>
                                                    BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                when REGISTER_ACC =>
                                                    BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                when others =>
                                                    report "illegal argument" severity note;
                                            end case;
                                            CTRL_PC_WE <= '0';
                                            T_COUNT    <= s2;
                                        when s2 =>
                                            T_COUNT <= s3;
                                        when others =>
                                            BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                            CTRL_PC_WE  <= '0';
                                            T_COUNT     <= s1;
                                            next_state  <= EXECUTE_CYCLE;
                                    end case;
                            end case;
                        when COND_JUMP =>
                            CC := IR(3 downto 1);
                            if (IR(0) = '1') then
                                mode := IMMEDIATE;
                            else
                                mode := REG;
                            end if;
                            case mode IS
                                when IMMEDIATE =>
                                    case CC IS
                                        when IF_CARRY =>
                                            if (SCR(carry_flag) = '1') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_MAR_WE <= '0';
                                                        T_COUNT     <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    WHEN s3 =>
                                                        BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s4;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_EQUAL =>
                                            if (SCR(zero_flag) = '1') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_MAR_WE <= '0';
                                                        T_COUNT     <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    WHEN s3 =>
                                                        BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s4;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_OVERFLOW =>
                                            if (SCR(overflow_flag) = '1') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_MAR_WE <= '0';
                                                        T_COUNT     <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    WHEN s3 =>
                                                        BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s4;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_NO_CARRY =>
                                            if (SCR(carry_flag) = '0') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_MAR_WE <= '0';
                                                        T_COUNT     <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    WHEN s3 =>
                                                        BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s4;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_NOT_EQUAL =>
                                            if (SCR(zero_flag) = '0') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_MAR_WE <= '0';
                                                        T_COUNT     <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    WHEN s3 =>
                                                        BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s4;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_NO_OVERFLOW =>
                                            if (SCR(overflow_flag) = '0') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_MAR_WE <= '0';
                                                        T_COUNT     <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    WHEN s3 =>
                                                        BUS_MUX_SEL <= to_unsigned(MEM_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s4;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when others =>
                                            report "not yet implemented" severity note;
                                    end case;
                                when others =>
                                    case CC IS
                                        when IF_CARRY =>
                                            if (SCR(carry_flag) = '1') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        case RR is
                                                            when REGISTER_B =>
                                                                BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_C =>
                                                                BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_ACC =>
                                                                BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                            when others =>
                                                                report "illegal argument" severity note;
                                                        end case;
                                                        CTRL_PC_WE <= '0';
                                                        T_COUNT    <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_EQUAL =>
                                            if (SCR(zero_flag) = '1') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        case RR is
                                                            when REGISTER_B =>
                                                                BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_C =>
                                                                BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_ACC =>
                                                                BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                            when others =>
                                                                report "illegal argument" severity note;
                                                        end case;
                                                        CTRL_PC_WE <= '0';
                                                        T_COUNT    <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_OVERFLOW =>
                                            if (SCR(overflow_flag) = '1') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        case RR is
                                                            when REGISTER_B =>
                                                                BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_C =>
                                                                BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_ACC =>
                                                                BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                            when others =>
                                                                report "illegal argument" severity note;
                                                        end case;
                                                        CTRL_PC_WE <= '0';
                                                        T_COUNT    <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_NO_CARRY =>
                                            if (SCR(carry_flag) = '0') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        case RR is
                                                            when REGISTER_B =>
                                                                BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_C =>
                                                                BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_ACC =>
                                                                BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                            when others =>
                                                                report "illegal argument" severity note;
                                                        end case;
                                                        CTRL_PC_WE <= '0';
                                                        T_COUNT    <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_NO_OVERFLOW =>
                                            if (SCR(overflow_flag) = '0') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        case RR is
                                                            when REGISTER_B =>
                                                                BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_C =>
                                                                BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_ACC =>
                                                                BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                            when others =>
                                                                report "illegal argument" severity note;
                                                        end case;
                                                        CTRL_PC_WE <= '0';
                                                        T_COUNT    <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when IF_NOT_EQUAL =>
                                            if (SCR(zero_flag) = '0') then
                                                case T_COUNT is
                                                    when s1 =>
                                                        case RR is
                                                            when REGISTER_B =>
                                                                BUS_MUX_SEL <= to_unsigned(B_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_C =>
                                                                BUS_MUX_SEL <= to_unsigned(C_REG_OUT, BUS_MUX_SEL'length);
                                                            when REGISTER_ACC =>
                                                                BUS_MUX_SEL <= to_unsigned(ACC_OUT, BUS_MUX_SEL'length);
                                                            when others =>
                                                                report "illegal argument" severity note;
                                                        end case;
                                                        CTRL_PC_WE <= '0';
                                                        T_COUNT    <= s2;
                                                    when s2 =>
                                                        T_COUNT <= s3;
                                                    when others =>
                                                        BUS_MUX_SEL <= to_unsigned(PC_INC_OUT, BUS_MUX_SEL'length);
                                                        CTRL_PC_WE  <= '0';
                                                        T_COUNT     <= s1;
                                                        next_state  <= EXECUTE_CYCLE;
                                                end case;
                                            end if;
                                        when others =>
                                            report "not yet implemented" severity note;
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

