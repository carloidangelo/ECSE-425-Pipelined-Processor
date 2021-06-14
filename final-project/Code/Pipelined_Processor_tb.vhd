--Pipelined_Processor_tb.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Pipelined_Processor_tb IS
END Pipelined_Processor_tb;

ARCHITECTURE behaviour OF Pipelined_Processor_tb IS

--Declare the component that you are testing:
    COMPONENT Pipelined_Processor IS
	generic(
		reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
		ram_size : INTEGER := 32768;
		mem_delay : time := 1.1 ns;
		instr_mem_size : integer := 4096;
		clock_period : time := 1 ns
	);
	port(
		clock : in std_logic
	);

    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;

BEGIN

    --dut => Device Under Test
    dut: Pipelined_Processor 
    PORT MAP(
	clock => clk
    );

    clk_process : process  -- Run for 10000 clock cycles
    BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
END;
