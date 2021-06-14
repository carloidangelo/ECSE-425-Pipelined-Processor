library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Data_Memory_tb is
end Data_Memory_tb;

architecture behaviour of Data_Memory_tb is
	component Data_Memory is
		generic(
			ram_size : INTEGER := 32768;
			mem_delay : time := 1 ns;
			clock_period : time := 1 ns
		);
		port (
			clock: IN STD_LOGIC;
			writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			address: IN INTEGER RANGE 0 TO ram_size-1;
			memwrite: IN STD_LOGIC;
			memread: IN STD_LOGIC;
			readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			waitrequest: OUT STD_LOGIC
		);
	end component;

    	--all the input signals with initial values
	signal clk : std_logic := '0';
	constant clk_period : time := 1 ns;
    	signal address: INTEGER RANGE 0 TO 4096-1;
  	signal memread: STD_LOGIC := '0';
	signal memwrite: STD_LOGIC := '0';
	signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal waitrequest: STD_LOGIC;
begin
	dut : Data_Memory
	port map(
		clock => clk, 
        	address => address,
       		memread => memread,
		memwrite => memwrite,
        	readdata => readdata,
		writedata => writedata,
       		waitrequest => waitrequest
	);

	clk_process : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	test_process : process
	begin
		-- initialize the input of memory
		-- put your tests here
		report "Test CASE 1: Write";
		address <= 0;
		memwrite <= '1';
		writedata <= "00000000000000000000000000000001";
		wait until rising_edge(waitrequest);
		memwrite <= '0';
		memread <= '1';
		wait until rising_edge(waitrequest);
		assert (readdata = "00000000000000000000000000000001") report "WRITE RES ERROR" severity ERROR;
		memread <= '0';
		report "--------------END-----------------";
		wait;
	end process;
end;
