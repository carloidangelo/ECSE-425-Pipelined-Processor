--Instruction_Memory_tb.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Instruction_Memory_tb IS
END Instruction_Memory_tb;

ARCHITECTURE behaviour OF Instruction_Memory_tb IS

--Declare the component that you are testing:
    COMPONENT Instruction_Memory IS
        GENERIC(
            instr_mem_size : INTEGER := 4096;
            mem_delay : time := 1 ns;
            clock_period : time := 1 ns
        );
        PORT (
            clock: IN STD_LOGIC;
            address: IN INTEGER RANGE 0 TO instr_mem_size-1;
            memread: IN STD_LOGIC := '0';
            readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            waitrequest: OUT STD_LOGIC
        );
    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    signal address: INTEGER RANGE 0 TO 4096-1;
    signal memread: STD_LOGIC := '0';
    signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal waitrequest: STD_LOGIC;

BEGIN

    --dut => Device Under Test
    dut: Instruction_Memory 
    PORT MAP(
	clock => clk,
        address => address,
       	memread => memread,
        readdata => readdata,
       	waitrequest => waitrequest
    );

    clk_process : process
    BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    test_process : process
    BEGIN
        wait for clk_period;
	
	-- Test case 1: Read a word from address 0
	report "Test case 1";
        address <= 0;
	memread <= '1'; 
        wait until rising_edge(waitrequest);
	assert readdata = "00100000000010110000011111010000" report "read unsuccessful" severity error;
	memread <= '0';
        wait for clk_period;
	
	-- Test case 2: Read a word from address 4
	report "Test case 2";
	address <= 4;
	memread <= '1'; 
        wait until rising_edge(waitrequest);
        assert readdata = "00100000000011110000000000000100" report "read unsuccessful" severity error;
	memread <= '0';
        wait for clk_period;

	-- Test case 3: Read a word from address 8
	report "Test case 3";
        address <= 8;
	memread <= '1'; 
	wait until rising_edge(waitrequest);
        assert readdata = "00100000000000010000000000000011" report "read unsuccessful" severity error;
        memread <= '0';
        wait;

    END PROCESS;

END;