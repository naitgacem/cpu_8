library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_8 is

	
	port 
	(	
		A     : IN unsigned(7 downto 0);
		B     : IN unsigned(7 downto 0);
		opcode: IN unsigned(3 downto 0);
		
		SCR   : OUT unsigned(7 downto 0);
		Y     : OUT unsigned(7 downto 0)
	);

end entity;

architecture arch of ALU_8 is
    
	 constant ADD            : unsigned(3 downto 0) := "0010";
    constant SUBTRACT       : unsigned(3 downto 0) := "0011";
    constant ADC            : unsigned(3 downto 0) := "0100";
    constant COMPARE        : unsigned(3 downto 0) := "0101";
    constant INCREMENT      : unsigned(3 downto 0) := "0110";
    constant DECREMENT      : unsigned(3 downto 0) := "0111";
    constant AND_OP         : unsigned(3 downto 0) := "1000";
    constant OR_OP          : unsigned(3 downto 0) := "1001";
    constant XOR_OP         : unsigned(3 downto 0) := "1010";
    constant SHIFT_LEFT_OP  : unsigned(3 downto 0) := "1011";
    constant SHIFT_RIGHT_OP : unsigned(3 downto 0) := "1100";
	
	 signal result           : unsigned(7 downto 0) := (others => '0');
	 signal FLAGS            : unsigned(7 downto 0) := (others => '0');
	 constant carry_flag : natural := 0;
	 constant zero_flag : natural := 1;
	 constant overflow_flag : natural := 2;
	 constant sign_flag : natural := 3;
begin	
	
	Y <= result;
	SCR <= FLAGS;
	
	process(A, B, opcode) 
	variable ans : unsigned(8 downto 0);
	begin
		case opcode is
			when ADD =>
				 ans := ('0' & A) + ('0' & B);
				 
			when SUBTRACT =>
				 ans := ('0' & A) - ('0' & B);
				 
			when ADC =>
				 ans := A + B + "" & FLAGS(carry_flag);
		
			when COMPARE =>
				 ans := ('0' & A) - ('0' & B);
				 result <= ans(7 downto 0);
				 
			when INCREMENT =>
				 ans := ('0' & A) + 1;
				 result <= ans(7 downto 0);
				 
			when DECREMENT =>
				 ans := ('0' & A) - 1;
				 
			when AND_OP =>
				 ans := '0' & A and '0' & B;
				 
			when OR_OP =>
				 ans := '0' & A or B;
				 
			when XOR_OP =>
				 ans := '0' & A xor B;
				 
			when SHIFT_LEFT_OP =>
				 ans := '0' & shift_left(A, to_integer(B));
				 
			when SHIFT_RIGHT_OP =>
				 ans := '0' & shift_right(A, to_integer(B));
			
			when others =>
				 ans := (others => '0');
		  end case;
		  result <= ans(7 downto 0);
		  FLAGS(carry_flag) <= ans(8);
		  
		  if(ans = 0) then 
			    FLAGS(zero_flag) <= '1';
		  else
				FLAGS(zero_flag) <= '0';
		  end if;
		  FLAGS(sign_flag) <= ans(7);
		  
		  if A(7) = B(7) and A(7) /= ans(7) then
		      FLAGS(overflow_flag) <= '1';
		  else
		      FLAGS(overflow_flag) <= '0';
        end if;
		  
	end process;
		  
	  
	  
			

end arch;
