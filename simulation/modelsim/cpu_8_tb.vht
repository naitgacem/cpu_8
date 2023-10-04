library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity cpu_8_tb is
end entity;

architecture testbench of cpu_8_tb is
    signal clk, reset : std_logic := '0';
    component cpu_8
        port(
            clk   : in std_logic;
            reset : in std_logic
        );
    end component;

begin
    -- Instantiate the CPU entity
    uut : cpu_8
        port map(
            clk   => clk,
            reset => reset
        );

    -- Clock generation
    clk_process : process
    begin
        while now < 1000 ns loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Reset generation
    reset_process : process
    begin
        reset <= '0';
        wait for 10 ns;
        reset <= '1';
        wait;
    end process;

    -- Stimulus process (write your test scenarios here)
    stimulus : process
    begin
        -- You can write your test cases here
        -- For example:
        -- wait for 20 ns;
        -- reset <= '1';
        -- wait for 10 ns;
        -- reset <= '0';
        -- wait for 50 ns;
        -- assert external_data = "01010101" report "Test failed!" severity error;
        wait;
    end process;

end testbench;
