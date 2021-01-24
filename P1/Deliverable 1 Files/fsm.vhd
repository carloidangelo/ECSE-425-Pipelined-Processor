library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

-- Do not modify the port map of this structure
entity comments_fsm is
port (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
end comments_fsm;

architecture behavioral of comments_fsm is

-- The ASCII value for the '/', '*' and end-of-line characters
constant SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
constant STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
constant NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

-- The States
type states is (S0,S1,S2,S3,S4);
signal current_state : states;

begin

-- Insert your processes here
fsm: process (clk, reset)
begin
	if (reset = '1') then 
		current_state <= S0;
		output <= 'X'; 

	elsif (rising_edge(clk)) then
		case current_state is
			when S0 =>
				if (input = SLASH_CHARACTER) then
					output <= '0';
					current_state <= S1;
				else
					output <= '0';
					current_state <= S0;
				end if; 
			when S1 =>
				if (input = SLASH_CHARACTER) then
					output <= '0';
					current_state <= S2;
				elsif (input = STAR_CHARACTER) then
					output <= '0';
					current_state <= S3;
				else
					output <= '0';
					current_state <= S0;
				end if; 
			when S2 =>
				if (input = NEW_LINE_CHARACTER) then
					output <= '1';
					current_state <= S0;
				else
					output <= '1';
					current_state <= S2;
				end if; 
			when S3 =>
				if (input = STAR_CHARACTER) then
					output <= '1';
					current_state <= S4;
				else
					output <= '1';
					current_state <= S3;
				end if; 
			when S4 =>
				if (input = SLASH_CHARACTER) then
					output <= '1';
					current_state <= S0;
				else
					output <= '1';
					current_state <= S3;
				end if; 
			when others =>
				null;
		end case;
	end if;
end process;
end behavioral;