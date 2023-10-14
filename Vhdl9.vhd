library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity vhdl9 is
    port(
        a       : in  unsigned(3 downto 0);
        b       : in  unsigned(3 downto 0);
        sel     : in  std_logic_vector(2 downto 0);
        hex0    : out std_logic_vector(6 downto 0);
        y       : out unsigned(3 downto 0);
        n, c, z : out std_logic
    );
end entity;
architecture arch of vhdl9 is
begin

    process(a, b, sel)
        variable ans : unsigned(4 downto 0) := (others => '0');
    begin
        case sel is
            when "000" =>
                ans := '0' & a;
            when "001" =>
                ans := unsigned('0' & a) + unsigned('0' & b);
            when "010" =>
                ans := unsigned('0' & a) - unsigned('0' & b);
            when "011" =>
                ans := unsigned('0' & a) or unsigned('0' & b);
            when "100" =>
                ans := unsigned('0' & a) and unsigned('0' & b);
            when "101" =>
                ans := unsigned('0' & a) nand unsigned('0' & b);
            when "110" =>
                ans := '0' & (not a);
            when others =>
                ans := '0' & (not b);
        end case;
        y <= ans(3 downto 0);
        n <= ans(3);
        c <= ans(4);
        if (ans = 0) then
            z <= '1';
        else
            z <= '0';
        end if;

        case ans(3 downto 0) is
            When "0000" =>
                hex0 <= "1000000";
            When "0001" =>
                hex0 <= "1111001";
            When "0010" =>
                hex0 <= "0100100";
            When "0011" =>
                hex0 <= "0110000";
            When "0100" =>
                hex0 <= "0011001";
            When "0101" =>
                hex0 <= "0010010";
            When "0110" =>
                hex0 <= "0000010";
            When "0111" =>
                hex0 <= "1111000";
            When "1000" =>
                hex0 <= "0000000";
            When "1001" =>
                hex0 <= "0011000";
            When "1010" =>
                hex0 <= "0001000";
            When "1011" =>
                hex0 <= "0000011";
            When "1100" =>
                hex0 <= "1000110";
            When "1101" =>
                hex0 <= "0100001";
            When "1110" =>
                hex0 <= "0000100";
            When others =>
                hex0 <= "0001110";
        end case;
    end process;
end;
