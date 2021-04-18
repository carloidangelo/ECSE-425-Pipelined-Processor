--Write_Back.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Write_Back is
	generic(
		instr_mem_size : integer := 4096;
		reg_size : INTEGER := 32 --reg size = 2^5 addressing depth
	);
	port (
		clock: in std_logic;
		rd: in INTEGER RANGE 0 TO reg_size-1;
		d_waitrequest: in std_logic;
		mem_status: in std_logic;
		readdata : in std_logic_vector (31 downto 0);
		alu_result : in std_logic_vector (31 downto 0)
	);
end Write_Back;

architecture behaviour of Write_Back is

signal status_sync: std_logic := '0';
signal reg_write : std_logic := '1';
signal rs: INTEGER := 0;
signal rt: INTEGER := 0; 
signal read_data1_signal: std_logic_vector(31 downto 0);
signal read_data2_signal: std_logic_vector(31 downto 0);

signal write_data : std_logic_vector(31 downto 0);

------- register block component
component RegisterBlock is 
	generic(
		reg_size : INTEGER := 32 --reg size = 2^5 addressing depth
	);
	port(
		clock: in std_logic;
		reg_write: in std_logic; -- register write enable signal
		write_data: in std_logic_vector(31 downto 0);
		write_address: in INTEGER RANGE 0 TO reg_size-1;
		read_address1 : in INTEGER RANGE 0 TO reg_size -1; -- rs (src address 1)
		read_address2 : in INTEGER RANGE 0 TO reg_size -1; -- rt (src address 2)
		data_out1 : out std_logic_vector (31 downto 0); -- rs (data at src 1)
		data_out2 : out std_logic_vector (31 downto 0) -- rt (data at src 2)
	);
end component;

begin

reg: RegisterBlock port map (
						clock => clock,
						reg_write => reg_write, -- register write enable signal
						write_data => write_data,
						write_address => rd,
						read_address1 => rs, -- rs (src address 1)
						read_address2 => rt, -- rt (src address 2)
						data_out1 => read_data1_signal, -- rs (data at src 1)
						data_out2 => read_data2_signal -- rt (data at src 2)
						);

	execute: process (clock)
	begin
		if (falling_edge(clock)) then
			if (d_waitrequest = '1' and status_sync = '1') then
				if (mem_status = '1') then
					write_data <= readdata;
				else 
					write_data <= alu_result;
				end if;
				status_sync <= '0';
			elsif (d_waitrequest = '0') then
				status_sync <= '1';
			else 
				status_sync <= '0';
			end if;
		end if;
	end process;

end behaviour;