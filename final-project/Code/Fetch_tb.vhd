library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fetch_tb is
end Fetch_tb;

architecture behavior of Fetch_tb is

component Fetch is
	generic(
		instr_mem_size : integer := 4096
	);
	port (
		clock: in std_logic;
		pc_updated : out integer range 0 to instr_mem_size-1;
		instr : out std_logic_vector (31 downto 0);
		pc_branch : in integer range 0 to instr_mem_size-1;
		branch_taken : in std_logic;
		i_waitrequest : out std_logic := '1';
 		status : out std_logic := '1';

		m_addr : out integer range 0 to instr_mem_size-1;
		m_read : out std_logic := '0';
		m_readdata : in std_logic_vector (31 downto 0);
		m_waitrequest : in std_logic;

		mem_status : in std_logic;
		d_waitrequest : in std_logic;
		delay: in std_logic
	);
end component;

component Instruction_Memory is 
        generic(
            instr_mem_size : integer := 4096;
            mem_delay : time := 1.1 ns;
            clock_period : time := 1 ns
        );
        port (
            clock: in std_logic;
            address: in integer range 0 to instr_mem_size-1;
            memread: in std_logic;
            readdata: out std_logic_vector (31 downto 0);
            waitrequest: out std_logic
        );
end component;
	
--all the input signals with initial values
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal pc_updated : integer range 0 to 4096-1;
signal instr : std_logic_vector (31 downto 0);
signal pc_branch : integer range 0 to 4096-1;
signal branch_taken : std_logic;
signal i_waitrequest : std_logic;
signal status : std_logic;
signal m_addr : integer range 0 to 4096-1;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (31 downto 0);
signal m_waitrequest : std_logic;
signal mem_status : std_logic;
signal d_waitrequest : std_logic;
signal delay: std_logic;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut_fetch: Fetch
port map(
	clock => clk,
	pc_updated => pc_updated,
	instr => instr,
	pc_branch => pc_branch,
	branch_taken => branch_taken,
	i_waitrequest => i_waitrequest,
	status => status,
	m_addr => m_addr,
	m_read => m_read,
	m_readdata => m_readdata,
	m_waitrequest => m_waitrequest,
	mem_status => mem_status,
	d_waitrequest => d_waitrequest,
	delay => delay
);


dut_mem: Instruction_Memory 
port map(
	clock => clk,
        address => m_addr,
       	memread => m_read,
        readdata => m_readdata,
       	waitrequest => m_waitrequest
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
	mem_status <= '1'; -- assume memory stage is being used
	d_waitrequest <= '0';	-- assume memory stage is finished processing read/write
	delay <= '0'; -- assume there are no data hazards

	-- Test case 1: Fetch instruction pc = 0
	report "Test case 1";
	pc_branch <= 5;
	branch_taken <= '0';
        wait until rising_edge(i_waitrequest);
	assert instr = "00100000000010110000011111010000" report "read unsuccessful" severity error;
	assert pc_updated = 4 report "update unsuccessful" severity error;
	
	mem_status <= '0'; -- assume memory stage is not being used

	-- Test case 2: Fetch instruction pc = 4
	report "Test case 2";
	pc_branch <= 16;
	branch_taken <= '1'; -- branch taken, so pc = 16 at next fetch
        wait until rising_edge(i_waitrequest);
	assert instr = "00100000000011110000000000000100" report "read unsuccessful" severity error;
	assert pc_updated = 8 report "update unsuccessful" severity error;

	-- Test case 3: Fetch instruction pc = 16
	report "Test case 3";
	pc_branch <= 16;
	branch_taken <= '0';
        wait until rising_edge(i_waitrequest);
	assert instr = "00000000001000100001100000100100" report "read unsuccessful" severity error;
	assert pc_updated = 20 report "update unsuccessful" severity error;
	
	-- Test case 4: Fetch instruction pc = 20
	report "Test case 4";
	pc_branch <= 16;
	branch_taken <= '0';
        wait until rising_edge(i_waitrequest);
	assert instr = "00100000000010100000000000000000" report "read unsuccessful" severity error;
	assert pc_updated = 24 report "update unsuccessful" severity error;

	wait;
end process;
end;