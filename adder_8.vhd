library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_8 is

	port(
		D : IN  std_logic_vector(7 downto 0);
		Q : OUT std_logic_vector(7 downto 0)
	);

end entity;

architecture arch of adder_8 is
begin

	Q <= std_logic_vector(unsigned(D) + 1);

end arch;
