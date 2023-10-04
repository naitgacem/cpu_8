library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity REG_8 is

	
	port 
	(
		clk   : IN std_logic;
		reset : IN std_logic;		
		WE    : IN std_logic;
		D     : IN std_logic_vector(7 downto 0);
		Q     : OUT std_logic_vector(7 downto 0)
	);

end entity;

architecture arch of REG_8 is

signal data : std_logic_vector(7 downto 0);
	
begin	
	process(clk, reset)
	begin
	if(reset = '0') then 
		data <= (others => '0');
	elsif rising_edge(clk) then
		if(WE = '0') then --writing to reg
				data <= std_logic_vector(d);
			end if;
		end if;
	end process;
	
	Q <= data;
	

end arch;
