--PipelinedProcessor.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipelined_Processor is
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
end component;


--INSTRUCTION EXECUTE---
--component Execute is
--port();
--end component;
---***********************---



---MEMORY-----
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
		f_waitrequest: in std_logic;
		d_waitrequest: in std_logic;
		mem_status: in std_logic;
		readdata : in std_logic_vector (31 downto 0);
		alu_result : in std_logic_vector (31 downto 0)
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
	signal delay: std_logic


----DECODE
	signal f_waitrequest: std_logic;
	signal	pc_updated_delay : integer range 0 to instr_mem_size-1;
	signal	read_data1 : std_logic_vector(31 downto 0); 
	signal	read_data2 : std_logic_vector(31 downto 0); 
	signal	extended_immediate : std_logic_vector (31 downto 0); -- extended immediate value
	signal	alu_opcode : std_logic_vector (4 downto 0); -- operation code for ALU
	signal	address : std_logic_vector (31 downto 0);
	signal	rd_address: INTEGER RANGE 0 TO reg_size -1; -- destination register address	

---EXECUTE



----MEMORY
	signal writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal memaddress: INTEGER RANGE 0 TO ram_size-1;
	signal memwrite: STD_LOGIC;
	signal memread: STD_LOGIC;
	signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal waitrequest: STD_LOGIC


-----WRITE BACK
	signal mem_status: std_logic;
	signal alu_result : std_logic_vector (31 downto 0)
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
		address => address,
		rd_address => rd_address, -- destination register address	
		
		-- data hazard detections
		delay => delay --- this is preset to 0, will it work ???
);

----TOD0
instruction_execute: Execute
port map( );


memory: Data_Memory 
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
		rd => rd_addresss,
		f_waitrequest => f_waitrequest,
		d_waitrequest => d_waitrequest,
		mem_status => mem_status,
		readdata => readdata,
		alu_result => alu_result

);


end architecture;