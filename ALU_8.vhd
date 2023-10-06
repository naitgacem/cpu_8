library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity ALU_8 is

    port(
        A      : IN  std_logic_vector(7 downto 0);
        B      : IN  std_logic_vector(7 downto 0);
        opcode : IN  std_logic_vector(3 downto 0);
        SCR    : OUT std_logic_vector(7 downto 0);
        Y      : OUT std_logic_vector(7 downto 0)
    );

end entity;

architecture arch of ALU_8 is

    constant ADD            : std_logic_vector(3 downto 0) := "0010";
    constant SUBTRACT       : std_logic_vector(3 downto 0) := "0011";
    constant ADC            : std_logic_vector(3 downto 0) := "0100";
    constant COMPARE        : std_logic_vector(3 downto 0) := "0101";
    constant INCREMENT      : std_logic_vector(3 downto 0) := "0110";
    constant DECREMENT      : std_logic_vector(3 downto 0) := "0111";
    constant AND_OP         : std_logic_vector(3 downto 0) := "1000";
    constant OR_OP          : std_logic_vector(3 downto 0) := "1001";
    constant XOR_OP         : std_logic_vector(3 downto 0) := "1010";
    constant SHIFT_LEFT_OP  : std_logic_vector(3 downto 0) := "1011";
    constant SHIFT_RIGHT_OP : std_logic_vector(3 downto 0) := "1100";

    signal result          : std_logic_vector(7 downto 0) := (others => '0');
    signal FLAGS           : std_logic_vector(7 downto 0) := (others => '0');
    constant carry_flag    : natural                      := 0;
    constant zero_flag     : natural                      := 1;
    constant overflow_flag : natural                      := 2;
    constant sign_flag     : natural                      := 3;
begin

    Y   <= result;
    SCR <= FLAGS;

    process(A, B, opcode, FLAGS)
        variable ans  : unsigned(8 downto 0);
        variable A_OP : unsigned(7 downto 0) := (others => '0');
        variable B_OP : unsigned(7 downto 0) := (others => '0');

    begin
        A_OP              := unsigned(A);
        B_OP              := unsigned(B);
        --report "we are here " & unsigned'image(A_OP) & " " severity NOTE;
        case opcode is
            when ADD =>
                ans := ('0' & A_OP) + ('0' & B_OP);

            when SUBTRACT =>
                ans := ('0' & A_OP) - ('0' & B_OP);

            when ADC =>
                ans := A_OP + B_OP + "0000000" & FLAGS(carry_flag);

            when COMPARE =>
                ans    := ('0' & A_OP) - ('0' & B_OP);
                result <= std_logic_vector(ans(7 downto 0));

            when INCREMENT =>
                ans    := ('0' & A_OP) + 1;
                result <= std_logic_vector(ans(7 downto 0));

            when DECREMENT =>
                ans := ('0' & A_OP) - 1;

            when AND_OP =>
                ans := '0' & A_OP and '0' & B_OP;

            when OR_OP =>
                ans := '0' & A_OP or '0' & B_OP;

            when XOR_OP =>
                ans := '0' & A_OP xor '0' & B_OP;

            when SHIFT_LEFT_OP =>
                ans := '0' & shift_left(A_OP, to_integer(B_OP));

            when SHIFT_RIGHT_OP =>
                ans := '0' & shift_right(A_OP, to_integer(B_OP));

            when others =>
                ans := (others => '0');
        end case;
        result            <= std_logic_vector(ans(7 downto 0));
        FLAGS(carry_flag) <= ans(8);

        if (ans = 0) then
            FLAGS(zero_flag) <= '1';
        else
            FLAGS(zero_flag) <= '0';
        end if;
        FLAGS(sign_flag) <= ans(7);

        if A_OP(7) = B_OP(7) and A_OP(7) /= ans(7) then
            FLAGS(overflow_flag) <= '1';
        else
            FLAGS(overflow_flag) <= '0';
        end if;

    end process;

end arch;
