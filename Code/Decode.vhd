--Decode.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decode is
	generic(
		instr_mem_size : integer := 4096;
		reg_size : INTEGER := 32 --reg size = 2^5 addressing depth
	);
	port( 
		clock: in std_logic;
		f_waitrequest: in std_logic;
		d_waitrequest: in std_logic;
		instruction: in std_logic_vector (31 downto 0);
		pc_updated : in integer range 0 to instr_mem_size-1;
		pc_updated_delay : out integer range 0 to instr_mem_size-1;
		read_data1 : out std_logic_vector(31 downto 0); 
		read_data2 : out std_logic_vector(31 downto 0); 
		extended_immediate : out std_logic_vector (31 downto 0); -- extended immediate value
		alu_opcode : out std_logic_vector (4 downto 0); -- operation code for ALU
		address : out std_logic_vector (31 downto 0);
		
		rd_address: out INTEGER RANGE 0 TO reg_size -1; -- destination register address	
		
		-- data hazard detections
		delay: out std_logic := '0'
		
		);
end Decode;
	
architecture decode_behavior of Decode is

signal extend_immediate: std_logic_vector(31 downto 0);
signal zero_extend:  std_logic_vector(15 downto 0) := (others => '0'); --zero extend 16b
signal zero_six_extend:  std_logic_vector(5 downto 0) := (others => '0'); --zero extend 6b
signal opcode : std_logic_vector(5 downto 0);
signal rs : INTEGER RANGE 0 TO reg_size -1; 
signal rt : INTEGER RANGE 0 TO reg_size -1; 
signal rd : INTEGER RANGE 0 TO reg_size -1; 
signal shamt : std_logic_vector(4 downto 0);
signal funct : std_logic_vector(5 downto 0);
---jtypes have address bits, currently not sure what to do with address
signal j_address: std_logic_vector(25 downto 0); 
signal read_data1_signal: std_logic_vector(31 downto 0);
signal read_data2_signal: std_logic_vector(31 downto 0);

-- data hazard detections
signal rd_delay1: INTEGER RANGE 0 TO reg_size -1;
signal rd_delay2: INTEGER RANGE 0 TO reg_size -1;
signal counter1: INTEGER := 2;

signal reg_write: std_logic := '0';
signal write_address: INTEGER RANGE 0 TO reg_size -1;
signal write_data: std_logic_vector(31 downto 0); 

------- register block component
component RegisterBlock is 
	port(
		clk : in std_logic;
		f_waitrequest: in std_logic;
		d_waitrequest: in std_logic;
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
						clk => clock,
						f_waitrequest => f_waitrequest,
						d_waitrequest => d_waitrequest,
						reg_write => reg_write, -- register write enable signal
						write_data => write_data,
						write_address => write_address,
						read_address1 => rs, -- rs (src address 1)
						read_address2 => rt, -- rt (src address 2)
						data_out1 => read_data1_signal, -- rs (data at src 1)
						data_out2 => read_data2_signal -- rt (data at src 2)
						);

decoding: process(clock)	

variable op_temp : std_logic_vector(5 downto 0);
variable rs_temp : INTEGER RANGE 0 TO reg_size -1; 
variable rt_temp : INTEGER RANGE 0 TO reg_size -1; 
variable rd_temp : INTEGER RANGE 0 TO reg_size -1; 

variable funct_temp : std_logic_vector(5 downto 0);
---jtypes have address bits, currently not sure what to do with address
variable j_address_temp: std_logic_vector(25 downto 0);


begin
		if(rising_edge(clock)) then
			--all instruction types
			op_temp := instruction(31 downto 26);	
			rs_temp := to_integer(unsigned(instruction(25 downto 21)));
			if op_temp = "000000" then --Rtype
			--NB: Instruction is in descending order
				rt_temp := to_integer(unsigned(instruction(20 downto 16)));
				rd_temp := to_integer(unsigned(instruction(15 downto 11)));
				shamt <= instruction(10 downto 6);
				funct_temp := instruction(5 downto 0);	
				
				
				rd_delay1 <= rd_temp;
				rd_delay2 <= rd_delay1;
				
				case(funct_temp) is
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
				-- stall pipeline for 2 clock cycles
				if (rs_temp = rd_delay1 or counter1 = 1 or rt_temp = rd_delay1) then
					rd_temp := 0;
					rs_temp := 0;
					alu_opcode <= "00000";
					delay <= '1';
					counter1 <= counter1 - 1;
				else 
					counter1 <= 2;
				end if;
				-- stall pipeline for 1
				if (rs_temp = rd_delay2 or rt_temp = rd_delay2) then
					rd_temp := 0;
					rs_temp := 0;
					alu_opcode <= "00000";
					delay <= '1';
				end if;
				rs<=rs_temp;
				rt<=rt_temp;
				rd<=rd_temp;
				
			elsif op_temp = "000010" then -- Jtype
				-- j
				address <= zero_six_extend & instruction(25 downto 0);
				alu_opcode <= "01111";
			elsif op_temp = "000011" then -- Jtype
				-- jal
				address <= zero_six_extend & instruction(25 downto 0);
				alu_opcode <= "10000";       

			else -- Itype
				rd_temp := to_integer(unsigned(instruction(20 downto 16))); --rd = rt for Itype
				rd_delay1 <= rd_temp;
				rd_delay2 <= rd_delay1;
				
				case(op_temp) is
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
				-- stall pipeline for 2 clock cycles
				if (rs_temp = rd_delay1 or counter1 = 1) then
					rd_temp := 0;
					rs_temp := 0;
					alu_opcode <= "00000"; --add instruction
					delay <= '1';
					counter1 <= counter1 - 1;
				else 
					counter1 <= 2;
				end if;
				-- stall pipeline for 1 clock cycle
				if (rs_temp = rd_delay2) then
					rd_temp := 0;
					rs_temp := 0; 
					alu_opcode <= "00000"; --add instruction
					delay <= '1';
				end if;
				rs<=rs_temp;	
				rd<=rd_temp;
			end if; 
		end if;
	end process;
	
	--set the respective signals
	extended_immediate <= extend_immediate;
	read_data1 <= read_data1_signal;
	read_data2 <= read_data2_signal;
	rd_address <= rd;
end decode_behavior;
	
	