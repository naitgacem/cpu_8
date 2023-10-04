library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX_8_CH is
	port(
		 sel     : in    unsigned(2 downto 0);
		 
		 d0      : in    std_logic_vector(7 downto 0);
		 d1      : in    std_logic_vector(7 downto 0);
		 d2      : in    std_logic_vector(7 downto 0);
		 d3      : in    std_logic_vector(7 downto 0);
		 d4      : in    std_logic_vector(7 downto 0);
		 d5      : in    std_logic_vector(7 downto 0);
		 d6      : in    std_logic_vector(7 downto 0);
		 d7      : in    std_logic_vector(7 downto 0);
		 
		 y       : out   std_logic_vector(7 downto 0)
  );

end entity;

architecture arch of MUX_8_CH is
	
begin
	
	
	with sel select y <= d0 when "000",
                     d1 when "001",
                     d2 when "010",
                     d3 when "011",
							d4 when "100",
							d5 when "101",
							d6 when "110",
							d7 when others;

end arch;
