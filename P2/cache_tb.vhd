library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
generic(
    ram_size : INTEGER := 32768
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
    s_addr : in std_logic_vector (31 downto 0);
    s_read : in std_logic;
    s_readdata : out std_logic_vector (31 downto 0);
    s_write : in std_logic;
    s_writedata : in std_logic_vector (31 downto 0);
    s_waitrequest : out std_logic; 

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 32768 - 1;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
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
	report "Initialization (setting current state to idle)";
	reset <= '1';
	s_write <= '0';
	s_read <= '0';
	wait for 1 * clk_period;
	reset <= '0';
	wait for 1 * clk_period;

	-- Test case 1: Cache Miss (Read)
	report "Test case 1, invalid + not dirty + read + tag equal";
        s_addr <= x"00000000";
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
	assert s_readdata = x"03020100" report "read data is wrong" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 0.
	-- The current cache block at index 0 is invalid.
	-- The current cache block at index 0 is not dirty.
	-- The current cache block at index 0 will have tag equal because the cache is initialized with entries containing only zeroes.
	-- The cache will access main memory and replace this block.
	-- The new cache block at index 0 is valid.
	-- The new cache block at index 0 is not dirty.
	-- The new cache block at index 0 will have a tag of "000000".

	-- Test case 2: Cache Miss (Read)
	report "Test case 2, invalid + not dirty + read + tag not equal";
        s_addr <= x"00001010";
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
	assert s_readdata = x"13121110" report "read data is wrong" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "001000" and that its index in the cache is 1.
	-- The current cache block at index 1 is invalid.
	-- The current cache block at index 1 is not dirty.
	-- The current cache block at index 1 will have tag not equal.
	-- The cache will access main memory and replace this block.
	-- The new cache block at index 1 is valid.
	-- The new cache block at index 1 is not dirty.
	-- The new cache block at index 1 will have a tag of "001000".

	-- Test case 3: Cache Miss (Read)
	report "Test case 3, valid + not dirty + read + tag not equal";
        s_addr <= x"00002010";
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
	assert s_readdata = x"13121110" report "read data is wrong" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "010000" and that its index in the cache is 1.
	-- The current cache block at index 1 is valid.
	-- The current cache block at index 1 is not dirty.
	-- The current cache block at index 1 will have tag not equal.
	-- The cache will access main memory and replace this block.
	-- The new cache block at index 1 is valid.
	-- The new cache block at index 1 is not dirty.
	-- The new cache block at index 1 will have a tag of "010000".

	-- Test case 4: Cache Hit (Read)
	report "Test case 4, valid + not dirty + read + tag equal";
        s_addr <= x"00000000";
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
	assert s_readdata = x"03020100" report "read data is wrong" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 0.
	-- The current cache block at index 0 is valid.
	-- The current cache block at index 0 is not dirty.
	-- The current cache block at index 0 will have tag equal.
	-- This cache block will remain in the cache.

	-- Test case 5: Cache Hit (Write)
	report "Test case 5, valid + not dirty + write + tag equal";
        s_addr <= x"00000000";
	s_writedata <= x"15151515";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
	s_write <= '0';
	s_read <= '1';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"15151515" report "write did not work" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 0.
	-- The current cache block at index 0 is valid.
	-- The current cache block at index 0 is not dirty.
	-- The current cache block at index 0 will have tag equal.
	-- New data will be written to the cache block and its dirty bit will be set to '1'.

	-- Test case 6: Cache Hit (Read)
	report "Test case 6, valid + dirty + read + tag equal";
        s_addr <= x"00000000";
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
	assert s_readdata = x"15151515" report "read data is wrong" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 0.
	-- The current cache block at index 0 is valid.
	-- The current cache block at index 0 is dirty.
	-- The current cache block at index 0 will have tag equal.
	-- This cache block will remain in the cache.

	-- Test case 7: Cache Hit (Write)
	report "Test case 7, valid + dirty + write + tag equal";
        s_addr <= x"00000000";
	s_writedata <= x"28282828";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
	s_write <= '0';
	s_read <= '1';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"28282828" report "write did not work" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 0.
	-- The current cache block at index 0 is valid.
	-- The current cache block at index 0 is dirty.
	-- The current cache block at index 0 will have tag equal.
	-- New data will be written to the cache block.

	-- Test case 8: Cache Miss (Write)
	report "Test case 8, valid + dirty + write + tag not equal";
        s_addr <= x"00001000";
	s_writedata <= x"15151515";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
	s_write <= '0';
	s_read <= '1';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"15151515" report "write did not work" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "001000" and that its index in the cache is 0.
	-- The current cache block at index 0 is valid.
	-- The current cache block at index 0 is dirty. 
	-- The current cache block at index 0 will have tag not equal.
	-- The cache will access main memory and replace this block.
	-- New data will be written to the new cache block.
	-- The new cache block at index 0 is valid.
	-- The new cache block at index 0 is dirty.
	-- The new cache block at index 0 will have a tag of "001000".

	-- Test case 9: Cache Miss (Read)
	report "Test case 9, valid + dirty + read + tag not equal";
        s_addr <= x"00000000"; 
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
	assert s_readdata = x"28282828" report "read data is wrong" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 0.
	-- The current cache block at index 0 is valid.
	-- The current cache block at index 0 is dirty.
	-- The current cache block at index 0 will have tag not equal.
	-- The cache will access main memory and replace this block.
	-- The new cache block at index 0 is valid.
	-- The new cache block at index 0 is not dirty.
	-- The new cache block at index 0 will have a tag of "000000".

	-- Test case 10: Cache Miss (Write)
	report "Test case 10, valid + not dirty + write + tag not equal";
        s_addr <= x"00001010";
	s_writedata <= x"15151515";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
	s_write <= '0';
	s_read <= '1';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"15151515" report "write did not work" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "001000" and that its index in the cache is 1.
	-- The current cache block at index 1 is valid.
	-- The current cache block at index 1 is not dirty.
	-- The current cache block at index 1 will have tag not equal.
	-- The cache will access main memory and replace this block.
	-- New data will be written to the new cache block.
	-- The new cache block at index 1 is valid.
	-- The new cache block at index 1 is dirty.
	-- The new cache block at index 1 will have a tag of "001000".

	-- Test case 11: Cache Miss (Write)
	report "Test case 11, invalid + not dirty + write + tag equal";
        s_addr <= x"00000020";
	s_writedata <= x"11111111";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
	s_write <= '0';
	s_read <= '1';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"11111111" report "write did not work" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "000000" and that its index in the cache is 2.
	-- The current cache block at index 2 is invalid.
	-- The current cache block at index 2 is not dirty.
	-- The current cache block at index 2 will have tag equal because the cache is initialized with entries containing only zeroes.
	-- The cache will access main memory and replace this block.
	-- New data will be written to the new cache block.
	-- The new cache block at index 2 is valid.
	-- The new cache block at index 2 is dirty.
	-- The new cache block at index 2 will have a tag of "000000".

	-- Test case 12: Cache Miss (Write)
	report "Test case 12, invalid + not dirty + write + tag not equal";
        s_addr <= x"00001030";
	s_writedata <= x"11111111";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
	s_write <= '0';
	s_read <= '1';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"11111111" report "write did not work" severity error;
	s_read <= '0';
        wait for clk_period;
	-- The address tells us that the tag of the desired block is "001000" and that its index in the cache is 3.
	-- The current cache block at index 3 is invalid.
	-- The current cache block at index 3 is not dirty.
	-- The current cache block at index 3 will have tag not equal.
	-- The cache will access main memory and replace this block.
	-- New data will be written to the new cache block.
	-- The new cache block at index 3 is valid.
	-- The new cache block at index 3 is dirty. 
	-- The new cache block at index 3 will have a tag of "001000".

	wait;
end process;
end;