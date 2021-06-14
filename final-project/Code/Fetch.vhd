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
		pc_updated : out integer range 0 to instr_mem_size-1; -- signal that is passed to the ID stage
		instr : out std_logic_vector (31 downto 0); -- fetched instruction
		pc_branch : in integer; -- PC of branch if branch is taken
		branch_taken : in std_logic; -- boolean that keeps track of if a brach is taken/not taken
		i_waitrequest : out std_logic := '1';
		status : out std_logic := '1';
 		-- signals that interact with instrction memory
		m_addr : out integer range 0 to instr_mem_size-1;
		m_read : out std_logic := '0';
		m_readdata : in std_logic_vector (31 downto 0);
		m_waitrequest : in std_logic;
		-- synchronize signals that come from data memory
		mem_status : in std_logic;
		d_waitrequest : in std_logic;
		
		delay: in std_logic
	);
end Fetch;

architecture behaviour of Fetch is
	type states is (operating,reset); -- two states for fetch functionality
	signal current_state : states := operating;
	signal pc : integer range 0 to instr_mem_size-1;
begin

	fetching: process (clock)
	begin
		if (rising_edge(clock)) then
			case current_state is
				-- get instruction from instruction memory
				when operating =>
					if (delay = '0') then
						status <= '1';
						if (m_waitrequest = '1') then
							-- request an instruction from instruction memory
							m_addr <= pc;
							m_read <= '1';
							current_state <= operating;
						elsif (m_waitrequest = '0') then
							if (branch_taken = '0') then --multiplexer 
								pc <= pc + 4; -- no branches
							else
								pc <= pc_branch; -- branch is taken
							end if;
							pc_updated <= pc + 4;
							instr <= m_readdata;
							m_read <= '0';
							i_waitrequest <= '0'; -- notify other components that its output data is ready to consume
							current_state <= reset;
						end if;
					else
						status <= '0';
					end if;
				when reset =>
					-- get ready to fetch next instruction, must wait for Memory to finish load/store as well
					-- if it is being used, mem_status = '1' means that data memory is active
					if (mem_status = '1') then -- synchronize with data memory
						-- d_waitrequest = '0' means that output data of Memory stage is ready. Only start
						-- fetching next instruction in the next clock cycle when this happens
						if (d_waitrequest = '0') then -- d_waitrequest and mem_status come from data memory
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