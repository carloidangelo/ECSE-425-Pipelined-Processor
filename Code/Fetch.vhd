--Fetch.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fetch is
	generic(
		instr_mem_size : integer := 4096
	);
	port (
		clock: in std_logic;
		pc_updated : out integer range 0 to instr_mem_size-1;
		instr : out std_logic_vector (31 downto 0);
		pc_branch : in integer;
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
end Fetch;

architecture behaviour of Fetch is
	type states is (operating,reset);
	signal current_state : states := operating;
	signal pc : integer range 0 to instr_mem_size-1;
begin

	fetching: process (clock)
	begin
		if (rising_edge(clock)) then
			case current_state is
				when operating =>
					if (delay = '0') then
						status <= '1';
						if (m_waitrequest = '1') then
							m_addr <= pc;
							m_read <= '1';
							current_state <= operating;
						elsif (m_waitrequest = '0') then
							if (branch_taken = '0') then --multiplexer 
								pc <= pc + 4;
							else
								pc <= pc_branch;
							end if;
							pc_updated <= pc + 4;
							instr <= m_readdata;
							m_read <= '0';
							i_waitrequest <= '0';
							current_state <= reset;
						end if;
					else
						status <= '0';
					end if;
				when reset =>
					if (mem_status = '1') then
						if (d_waitrequest = '0') then
							i_waitrequest <= '1';
							current_state <= operating;
						else
							i_waitrequest <= '0';
							current_state <= reset;
						end if;
					else
						i_waitrequest <= '1';
						current_state <= operating;
					end if;
				when others =>
					null;
			end case;
		end if;
	end process;

end behaviour;