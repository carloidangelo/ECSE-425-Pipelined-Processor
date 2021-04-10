--Decode.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decode is
	generic(
		instr_mem_size : integer := 4096
	);
	port( 
		clock: in std_logic;
		instruction: in std_logic_vector (31 downto 0);
		pc_updated : in integer range 0 to instr_mem_size-1;
		pc_updated_delay : out integer range 0 to instr_mem_size-1;
		read_data1 : out std_logic_vector(31 downto 0) ; 
		read_data2 : out std_logic_vector(31 downto 0) ; 
		extended_immediate : out std_logic_vector (31 downto 0); -- extended immediate value
		alu_opcode : out std_logic_vector (4 downto 0) -- operation code for ALU
		--need to include register addresses write and write data
		);
end Decode;
	
architecture decode_behavior of Decode is

signal extend_immediate: std_logic_vector(31 downto 0);
signal zero_extend:  std_logic_vector(15 downto 0) := (others => '0');
signal opcode : std_logic_vector(5 downto 0);
signal rs : std_logic_vector(4 downto 0);
signal rt : std_logic_vector(4 downto 0);
signal rd : std_logic_vector(4 downto 0);
signal shamt : std_logic_vector(4 downto 0);
signal funct : std_logic_vector(5 downto 0);
signal address: std_logic_vector(25 downto 0);

begin	
decoding: process(clock)	
begin
		if(rising_edge(clock)) then
			--all instruction types
			opcode <= instruction(31 downto 26);	
			if opcode = "000000" then --Rtype
			--NB: Instruction is in descending order
				rs <= instruction(25 downto 21);
				rt <= instruction(20 downto 16);
				rd <= instruction(15 downto 11);
				shamt <= instruction(10 downto 6);
				funct <= instruction(5 downto 0);	
				case(funct) is
					when "100000" => 
						-- add
						alu_opcode <= "00000";
					when "100100" => 
						-- and
						alu_opcode <= "00001";
					when "011010" => 
						-- div
						alu_opcode <= "00010";
					when "100111" => 
						-- nor
						alu_opcode <= "00011";
               				when "100101" => 
						 -- or
						alu_opcode <= "00100";
        			      	when "101010" => 
						-- slt
						alu_opcode <= "00101";
              				when "100010" => 
					 	-- sub
						alu_opcode <= "00110";
               				when "100110" =>
						-- xor
						alu_opcode <= "00111";
               				when "011000" => 
						 -- mult
						alu_opcode <= "01000";      
               				when "010000" => 
					 	-- mfhi
						alu_opcode <= "01001";
               				when "010010" => 
						-- mflo
						alu_opcode <= "01010";
               				when "000011" => 
						-- sra
						alu_opcode <= "01011";
               				when "000000" => 
						-- sll
						alu_opcode <= "01100";
               				when "000010" => 
						-- srl
						alu_opcode <= "01101";
					when "001000" => 
						-- jr
						alu_opcode <= "01110";
					when others =>
						null;
				end case;
				
			elsif opcode = "000010" then -- Jtype
				-- j
				address <= instruction(25 downto 0);
				alu_opcode <= "01111";
			elsif opcode = "000011" then -- Jtype
				-- jal
				address <= instruction(25 downto 0);
				alu_opcode <= "10000";       

			else -- Itype
				case(opcode) is
					 when "001000" =>
						  -- addi
						  alu_opcode <= "10001";
						  extend_immediate <= std_logic_vector(resize(signed(instruction(15 downto 0)), extend_immediate'length));
					 when "001100" =>
						  -- andi
						  alu_opcode <= "10010";
						  extend_immediate <= zero_extend & instruction(15 downto 0); -- zero extended 
					 when "001101" =>
						  -- ori
						  alu_opcode <= "10011";
						  extend_immediate <= zero_extend & instruction(15 downto 0); -- zero extended 
					 when "001110" =>
						  -- xori
						  alu_opcode <= "10100";
						  extend_immediate <= zero_extend & instruction(15 downto 0); -- zero extended 
					 when "100011" =>
						  -- lw
						  alu_opcode <= "10101";
						  extend_immediate <= std_logic_vector(resize(signed(instruction(15 downto 0)), extend_immediate'length));
					 when "001111" =>
						  -- lui
						  alu_opcode <= "10110";
					 when "101011" =>
						  -- sw
						  alu_opcode <= "10111";
						  extend_immediate <= std_logic_vector(resize(signed(instruction(15 downto 0)), extend_immediate'length));  
					 when "001010" =>
						  -- slti
						  alu_opcode <= "11000";
						  extend_immediate <= std_logic_vector(resize(signed(instruction(15 downto 0)), extend_immediate'length));
					 when "000100" =>
						  -- beq
						  alu_opcode <= "11001";
						  extend_immediate <= std_logic_vector(resize(signed(instruction(15 downto 0)), extend_immediate'length));
					 when "000101" =>
						  -- bne
						  alu_opcode <= "11010";
						  extend_immediate <= std_logic_vector(resize(signed(instruction(15 downto 0)), extend_immediate'length));
					 when others => null;	  
				end case;
			end if;
		end if;
	end process;
	extended_immediate <= extend_immediate;
	--find a way to load data from register to be passed to ALU

end decode_behavior;
	
	