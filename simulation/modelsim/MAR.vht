LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                
USE ieee.numeric_std.all;

ENTITY MAR_vhd_tst IS
END MAR_vhd_tst;
ARCHITECTURE MAR_arch OF MAR_vhd_tst IS
                                                 
	SIGNAL d : unsigned(7 DOWNTO 0);
	SIGNAL OE : STD_LOGIC;
	SIGNAL reset : STD_LOGIC;
	SIGNAL RW : STD_LOGIC;
	SIGNAL WE : STD_LOGIC;
	COMPONENT MAR
		PORT (
		clk : IN STD_LOGIC;
		d : INOUT unsigned(7 DOWNTO 0);
		OE : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		RW : IN STD_LOGIC;
		WE : IN STD_LOGIC
		);
	END COMPONENT;

	signal clk : STD_LOGIC := '0';  -- Internal clock signal
	constant CLK_PERIOD : time := 40 ns;  -- Clock period (adjust as needed)
BEGIN
	i1 : MAR
	PORT MAP (
		clk => clk,
		d => d,
		OE => OE,
		reset => reset,
		RW => RW,
		WE => WE
	);
	
	init : PROCESS BEGIN                                                        
	   reset <= '0';
		wait for 5 ns;
		reset <= '1';
		WAIT;                                                       
	END PROCESS init;                                           
	
	always : PROCESS BEGIN 
		OE <= '1';
		WE <= '1';
		RW <= '0';
		wait for 15 ns;
		WE <= '0';
		d <= "00000100";
		wait for 7 ns;
		WE <= '1';
		wait for 10 ns;
		OE <= '1';
		RW <= '1';
		wait for 20 ns;
	WAIT;                                                        
	END PROCESS always;
	
	 gen_clk_process: process begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;
                                          
END MAR_arch;
