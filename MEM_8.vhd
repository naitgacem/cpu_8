-- Quartus II VHDL Template
-- Single-port RAM with single read/write address and initial contents	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEM_8 is

    generic(
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 6
    );

    port(
        clk  : in  std_logic;
        addr : in  natural range 0 to 2 ** ADDR_WIDTH - 1;
        data : in  std_logic_vector((DATA_WIDTH - 1) downto 0);
        we   : in  std_logic := '1';
        q    : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end MEM_8;

architecture rtl of MEM_8 is

    -- Build a 2-D array type for the RAM
    subtype word_t is std_logic_vector((DATA_WIDTH - 1) downto 0);
    type memory_t is array (2 ** ADDR_WIDTH - 1 downto 0) of word_t;

    function init_ram
    return memory_t is
        variable tmp : memory_t := (others => (others => '0'));
    begin
        tmp(0)  := x"04";               -- load b, 23h
        tmp(1)  := x"23";
        tmp(2)  := x"06";               -- load a, ffh
        tmp(3)  := x"FF";
        tmp(4)  := x"28";               -- add acc, b
        tmp(5)  := x"E9";               -- jmp c, 50h
        tmp(6)  := x"50";
        tmp(7)  := x"ad";
        tmp(8)  := x"be";               --0x02
        tmp(9)  := x"ef";
        tmp(10) := x"de";               -- add acc and b
        tmp(11) := x"ad";               -- inc    acc
        tmp(12) := x"be";               -- inc B     
        for addr_pos in 13 to 2 ** ADDR_WIDTH - 1 loop
            -- Initialize each address with the address itself
            tmp(addr_pos) := std_logic_vector(to_unsigned(addr_pos, DATA_WIDTH));
        end loop;
        return tmp;
    end init_ram;

    -- Declare the RAM signal and specify a default value.	Quartus II
    -- will create a memory initialization file (.mif) based on the 
    -- default value.
    signal ram : memory_t := init_ram;

    -- Register to hold the address 
    signal addr_reg : natural range 0 to 2 ** ADDR_WIDTH - 1;

begin

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (we = '1') then
                ram(addr) <= data;
            end if;

            -- Register the address for reading
            addr_reg <= addr;
        end if;
    end process;

    q <= ram(addr_reg);

end rtl;
