library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
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
end cache;

architecture arch of cache is

-- declare signals here
-- The States
type states is (idle,mem_read,mem_write,trans_complete);
signal current_state : states;

type cache is array(31 downto 0) of std_logic_vector(135 downto 0);
signal cache_total: cache := (others => (others => '0'));

begin

-- make circuits here
fsm: process (clock, reset)
constant word_size: integer range 0 to 32 := 32;
constant byte_size: integer range 0 to 8 := 8;
variable count: integer range 0 to 16;
variable word_offset: integer range 0 to 3;
variable index: integer range 0 to 31;
variable address_tag: std_logic_vector(5 downto 0);
variable temp_address: std_logic_vector(14 downto 0);
variable temp_count: std_logic_vector(4 downto 0);
variable cache_block: std_logic_vector(135 downto 0);
variable cache_block_tag: std_logic_vector(5 downto 0);
variable replace_block: std_logic_vector(135 downto 0) := (others => '0');
variable valid: std_logic;
variable dirty: std_logic;

begin
	if (reset = '1') then 
		current_state <= idle;
		s_waitrequest <= '1';
		count := 0;
		m_read <= '0';
		m_write <= '0';
	elsif (rising_edge(clock)) then
		case current_state is
			when idle =>
				word_offset := to_integer(unsigned(s_addr(3 downto 2)));
				index := to_integer(unsigned(s_addr(8 downto 4)));
				address_tag := s_addr(14 downto 9);
				cache_block := cache_total(index);
				cache_block_tag := cache_block(133 downto 128);
				valid := cache_block(134);
				if (s_read = '1' and (address_tag = cache_block_tag) and valid = '1') then
					s_readdata <= cache_block((((word_offset + 1) * word_size) - 1) downto (word_offset * word_size));
					s_waitrequest <= '0';
					current_state <= trans_complete;
				elsif (s_write = '1' and (address_tag = cache_block_tag) and valid = '1') then
					cache_block((((word_offset + 1) * word_size) - 1) downto (word_offset * word_size)) := s_writedata;
					cache_block(135) := '1';
					cache_total(index) <= cache_block;
					s_waitrequest <= '0';
					current_state <= trans_complete;
				elsif ((s_read = '1' or s_write = '1') and not((address_tag = cache_block_tag) and valid = '1')) then
					temp_address(14 downto 4) := s_addr(14 downto 4);
					current_state <= mem_read;
				elsif (s_read = '0' and s_write = '0') then
					current_state <= idle;
				end if; 
			when mem_read =>
				dirty := cache_block(135);
				if (m_waitrequest = '1') then
					m_read <= '1';
					temp_count := std_logic_vector(to_unsigned(count, 5));
					temp_address(3 downto 0) := temp_count(3 downto 0);
					m_addr <= to_integer(unsigned(temp_address));
					current_state <= mem_read;
				elsif (m_waitrequest = '0') then
					replace_block((((count + 1) * byte_size) - 1) downto (count * byte_size)) := m_readdata;
					m_read <= '0';
					current_state <= mem_read;
					if (count = 15) then
						replace_block(134) := '1';
						replace_block(133 downto 128):= s_addr(14 downto 9);
						if (s_read = '1') then
							cache_total(index) <= replace_block;
							s_readdata <= replace_block((((word_offset + 1) * word_size) - 1) downto (word_offset * word_size));
						elsif (s_write = '1') then
							replace_block((((word_offset + 1) * word_size) - 1) downto (word_offset * word_size)) := s_writedata;
							replace_block(135) := '1';
							cache_total(index) <= replace_block;
						end if;
						if (dirty = '1') then 
							count := 0;
							current_state <= mem_write;
						else
							count := 0;
							s_waitrequest <= '0';
							current_state <= trans_complete;
						end if;

					else 
						count := count + 1;
					end if;
				end if;
			when mem_write =>
				if (m_waitrequest = '1') then
					m_write <= '1';
					m_writedata <= cache_block((((count + 1) * byte_size) - 1) downto (count * byte_size));
					current_state <= mem_write;
				elsif (m_waitrequest = '0') then
					m_write <= '0';
					current_state <= mem_write;
					if (count = 15) then 
						count := 0;
						s_waitrequest <= '0';
						current_state <= trans_complete;
					else
						count := count + 1;
					end if;
				end if;
			when trans_complete => 
				s_waitrequest <= '1';
				current_state <= idle;
			when others =>
				null;
		end case;
	end if;
end process;

end arch;