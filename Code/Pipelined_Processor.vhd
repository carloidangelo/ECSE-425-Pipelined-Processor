--PipelinedProcessor.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipelined_Processor is
generic(
		reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
		ram_size : INTEGER := 32768;
		mem_delay : time := 1 ns;
		instr_mem_size : integer := 4096
	);
port(
	clock : in std_logic
);

end Pipelined_Processor;

architecture behavior of Pipelined_Processor is


--INSTRUCTION FETCH--
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

--INSTRUCTION DECODE ---
component Decode is
generic(
		reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
		instr_mem_size : integer := 4096
	);
	port( 
		clock: in std_logic;
		-- synchronie with instruction memory (or data memory if hazard)
		f_waitrequest: in std_logic;
		d_waitrequest: in std_logic;
		-- instruction from IF stage
		instruction: in std_logic_vector (31 downto 0);
		-- PC + 4 from IF stage
		pc_updated : in integer range 0 to instr_mem_size-1;
		-- ID sends PC + 4 to EX stage for branch resolution
		pc_updated_delay : out integer range 0 to instr_mem_size-1;
		-- decoded values from instruction to send to EX stage
		read_data1 : out std_logic_vector(31 downto 0); 
		read_data2 : out std_logic_vector(31 downto 0); 
		extended_immediate : out std_logic_vector (31 downto 0);
		address : out std_logic_vector (31 downto 0);
		-- a code specifying what EX stage needs to do, based on the opcode of the instruction
		alu_opcode : out std_logic_vector (4 downto 0);
		-- destination register address for WB stage
		rd_address: out INTEGER RANGE 0 TO reg_size -1; 	
		-- send to IF stage to stall (hazard detection)
		delay: out std_logic := '0'
		);
end component;


--INSTRUCTION EXECUTE---
component Execute is
	generic(
			instr_mem_size : integer := 4096
		);
  port (
		input_X  : in std_logic_vector (31 downto 0); --alu
		input_Y  : in std_logic_vector (31 downto 0); --alu
		address : in std_logic_vector (31 downto 0); --alu
		alu_opcode : in std_logic_vector (4 downto 0); --alu
		alu_opcode_delayed : out std_logic_vector (4 downto 0); --alu
		pc_branch : out integer range 0 to instr_mem_size-1; --alu
		branch_taken : out std_logic:= '0'; --alu
		output_Z : out std_logic_vector(31 downto 0); --alu
		input_Y_delayed: out std_logic_vector (31 downto 0);
		immediate : in std_logic_vector (31 downto 0); -- extended immediate value --for adder
		pc_updated : in integer range 0 to instr_mem_size-1; --for adder
		rd_address : in INTEGER RANGE 0 TO reg_size -1;
		rd_address_delayed: out INTEGER RANGE 0 TO reg_size -1
  );
end component;


------- DATA MEMORY---------
component Data_Memory is
GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

---WRITEBACK-----
component Write_Back is
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
end component;

-----INSTRUCTION MEMORY-------
component Instruction_Memory is
GENERIC(
		instr_mem_size : INTEGER := 4096;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		address: IN INTEGER RANGE 0 TO instr_mem_size-1;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

-----MEMORY -----------------------
component Memory is
	generic(
		reg_size : INTEGER := 32; --reg size = 2^5 addressing depth
		data_mem_size : integer := 32768
	);
	port (
		clock: in std_logic;
		i_waitrequest : out std_logic := '1';
		f_waitrequest : in std_logic;
		alu_result : in std_logic_vector (31 downto 0);
		writedata : in std_logic_vector (31 downto 0);
		readdata : out std_logic_vector (31 downto 0);
		alu_opcode : in std_logic_vector (4 downto 0);
		status : out std_logic := '0';	
		fetch_status: in std_logic;
		alu_result_delay : out std_logic_vector (31 downto 0);
 
		m_addr : out integer range 0 to data_mem_size-1;
		m_read : out std_logic := '0';
		m_readdata : in std_logic_vector (31 downto 0);
		m_write : out std_logic := '0';
		m_writedata : out std_logic_vector (31 downto 0);
		m_waitrequest : in std_logic;
		
		rd_address: in INTEGER RANGE 0 TO reg_size -1; -- destination register address	
		rd_address_delay: out INTEGER RANGE 0 TO reg_size -1
	);
end component;

------------------------------ BEGIN SIGNAL DECLARATIONS------------------------------------
---FETCH
	signal pc_updated : integer range 0 to instr_mem_size-1;
	signal instr : std_logic_vector (31 downto 0);
	signal pc_branch : integer range 0 to instr_mem_size-1;
	signal branch_taken : std_logic;
	signal i_waitrequest : std_logic := '1';
	signal m_addr : integer range 0 to instr_mem_size-1;
	signal m_read : std_logic := '0';
	signal m_readdata : std_logic_vector (31 downto 0);
	signal m_waitrequest : std_logic;
	signal mem_status : std_logic;
	signal d_waitrequest : std_logic;	
	signal delay: std_logic;
	signal status : std_logic;


----DECODE
	signal f_waitrequest: std_logic;
	signal pc_updated_delay : integer range 0 to instr_mem_size-1;
	signal read_data1 : std_logic_vector(31 downto 0); 
	signal read_data2 : std_logic_vector(31 downto 0); 
	signal extended_immediate : std_logic_vector (31 downto 0); -- extended immediate value
	signal alu_opcode : std_logic_vector (4 downto 0); -- operation code for ALU
	signal rd_address: INTEGER RANGE 0 TO reg_size -1; -- destination register address	

---EXECUTE
	signal output_Z : std_logic_vector(31 downto 0);
	signal input_Y_delayed: std_logic_vector (31 downto 0);
	signal alu_opcode_delayed : std_logic_vector (4 downto 0); --alu
	signal EX_address : std_logic_vector (31 downto 0);
	signal rd_address_delayed: INTEGER RANGE 0 TO reg_size -1;
	
-----WRITE BACK
	signal alu_result : std_logic_vector (31 downto 0);
	
------DATA MEMORY
	signal writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal address: INTEGER RANGE 0 TO ram_size-1;
	signal memwrite: STD_LOGIC;
	signal memread: STD_LOGIC;
	signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal waitrequest: STD_LOGIC;
	
----MEMORY
	signal MM_readdata : std_logic_vector (31 downto 0);
	signal MM_writedata : std_logic_vector (31 downto 0);
	signal rd_address_delay: INTEGER RANGE 0 TO reg_size -1;

------------------------------- END SIGNAL DECLARATIONS------------------------------------
begin

instruction_fetch: Fetch
port map( 
		clock => clock,
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

instruction_decode: Decode
port map( 

		clock => clock,
		f_waitrequest => f_waitrequest,
		d_waitrequest => d_waitrequest,
		instruction => instr,
		pc_updated => pc_updated,
		pc_updated_delay => pc_updated_delay,
		read_data1 => read_data1, 
		read_data2 => read_data2, 
		extended_immediate => extended_immediate, -- extended immediate value
		alu_opcode => alu_opcode, -- operation code for ALU
		address => EX_address,
		rd_address => rd_address, -- destination register address	
		-- data hazard detections
		delay => delay --- this is preset to 0
);

----TOD0
instruction_execute: Execute
port map( 
		input_X => read_data1, --alu
		input_Y => read_data2, --alu
		address => EX_address, --alu
		alu_opcode => alu_opcode, --alu
		alu_opcode_delayed => alu_opcode_delayed,
		pc_branch => pc_branch, --alu
		branch_taken => branch_taken, --alu
		output_Z => output_Z, --alu
		input_Y_delayed => input_Y_delayed,
		immediate => extended_immediate,-- extended immediate value --for adder
		pc_updated => pc_updated, --for adder
		rd_address => rd_address,
		rd_address_delayed=> rd_address_delayed
);


mem: Data_Memory 
port map( 
		clock => clock,
		writedata => writedata,
		address => address,
		memwrite => memwrite,
		memread => memread,
		readdata => readdata,
		waitrequest => waitrequest
);

wb: Write_Back
port map( 
		clock => clock,
		rd => rd_address_delay,
		d_waitrequest => d_waitrequest,
		mem_status => mem_status,
		readdata => readdata,
		alu_result => alu_result

);

instrmem: Instruction_Memory
port map( 
		clock => clock,
		address => address,
		memread => memread,
		readdata => readdata,
		waitrequest  => waitrequest
);

str: Memory
port map (
		clock=> clock,
		i_waitrequest => d_waitrequest,
		f_waitrequest => i_waitrequest,
		alu_result => alu_result,
		writedata => MM_writedata,
		readdata => MM_readdata,
		alu_opcode => alu_opcode_delayed,
		status => mem_status,	
		fetch_status => status,
		alu_result_delay => alu_result,
 
		m_addr => address,
		m_read =>  memread,
		m_readdata => readdata,
		m_write => memwrite,
		m_writedata => writedata, 
		m_waitrequest => waitrequest,
		
		rd_address => rd_address_delayed, -- destination register address	
		rd_address_delay => rd_address_delay

);

end architecture;