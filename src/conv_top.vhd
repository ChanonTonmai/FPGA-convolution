use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity conv_top is
generic(
    MATRIX_WIDTH            : natural := 1; --!< The width of the Matrix Multiply Unit and busses.
    WEIGHT_BUFFER_DEPTH     : natural := 1024; --!< The depth of the weight buffer.
    UNIFIED_BUFFER_DEPTH    : natural := 4096 --!< The depth of the unified buffer.
);

Port (
    CLK, RESET          : in  std_logic;
    ENABLE              : in  std_logic;
    
    start               : in std_logic; 
    data_length         : in std_logic_vector(10 downto 0); 
    filter_size         : in std_logic_vector(7 downto 0); 
    dp_to_dma_start     : out std_logic; 
    
    addr_out_read       : in std_logic_Vector(12-1 downto 0);
    addr_out_en0        : in std_logic; 
    addr_out_read_port  : out std_logic_vector(31 downto 0);
             
    WEIGHT_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the weight buffer
    WEIGHT_ADDRESS      : in  WEIGHT_ADDRESS_TYPE; --!< Host address for the weight buffer.
    WEIGHT_ENABLE       : in  std_logic; --!< Host enable for the weight buffer.
    WEIGHT_WRITE_ENABLE : in  std_logic_vector(0 to MATRIX_WIDTH-1); --!< Host write enable for the weight buffer.
    
    BUFFER_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the unified buffer.
    BUFFER_READ_PORT    : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host read port for the unified buffer.
    BUFFER_ADDRESS      : in  BUFFER_ADDRESS_TYPE; --!< Host address for the unified buffer.
    BUFFER_ENABLE       : in  std_logic; --!< Host enable for the unified buffer.
    BUFFER_WRITE_ENABLE : in  std_logic_vector(0 to MATRIX_WIDTH-1) --!< Host write enable for the unified buffer.

);
end conv_top;

architecture Behavioral of conv_top is
component WEIGHT_BUFFER is
        generic(
            MATRIX_WIDTH    : natural := 1;
            -- How many tiles can be saved
            TILE_WIDTH      : natural := 1024
        );
        port(
            CLK, RESET      : in  std_logic;
            ENABLE          : in  std_logic;
            
            -- Port0
            ADDRESS0        : in  WEIGHT_ADDRESS_TYPE;
            EN0             : in  std_logic;
            WRITE_EN0       : in  std_logic;
            WRITE_PORT0     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            READ_PORT0      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            -- Port1
            ADDRESS1        : in  WEIGHT_ADDRESS_TYPE;
            EN1             : in  std_logic;
            WRITE_EN1       : in  std_logic_vector(0 to MATRIX_WIDTH-1);
            WRITE_PORT1     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
            READ_PORT1      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
        );
    end component WEIGHT_BUFFER;
    for all : WEIGHT_BUFFER use entity WORK.WEIGHT_BUFFER(BEH);
    
   signal WEIGHT_ADDRESS0      : WEIGHT_ADDRESS_TYPE;
   signal WEIGHT_EN0           : std_logic;
   signal WEIGHT_READ_PORT0    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
       
   component UNIFIED_BUFFER is
       generic(
           MATRIX_WIDTH    : natural := 1;
           -- How many tiles can be saved
           TILE_WIDTH      : natural := 4096
       );
       port(
           CLK, RESET      : in  std_logic;
           ENABLE          : in  std_logic;
           
           -- Master port - overrides other ports
           MASTER_ADDRESS      : in  BUFFER_ADDRESS_TYPE;
           MASTER_EN           : in  std_logic;
           MASTER_WRITE_EN     : in  std_logic_vector(0 to MATRIX_WIDTH-1);
           MASTER_WRITE_PORT   : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           MASTER_READ_PORT    : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           -- Port0
           ADDRESS0        : in  BUFFER_ADDRESS_TYPE;
           EN0             : in  std_logic;
           READ_PORT0      : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
           -- Port1
           ADDRESS1        : in  BUFFER_ADDRESS_TYPE;
           EN1             : in  std_logic;
           WRITE_EN1       : in  std_logic;
           WRITE_PORT1     : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
       );
   end component UNIFIED_BUFFER;
   for all : UNIFIED_BUFFER use entity WORK.UNIFIED_BUFFER(BEH);
   component macc_pe is
   Port (
       clk, reset : in std_logic; 
       A : in std_logic_vector(7 downto 0);
       B : in std_logic_vector(7 downto 0);
       R : out std_logic_vector(31 downto 0);
       filter_size : in std_logic_vector(7 downto 0); 
       finish : out std_logic; 
       ctrl : in std_logic_vector(7 downto 0)
    );
   end component;
   
   signal buffer_read_port0_vec : std_logic_vector(7 downto 0);
   signal weight_read_port0_vec : std_logic_vector(7 downto 0);
   
   signal BUFFER_ADDRESS0      : BUFFER_ADDRESS_TYPE;
   signal BUFFER_EN0           : std_logic;
   signal BUFFER_READ_PORT0    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   signal BUFFER_ADDRESS1      : BUFFER_ADDRESS_TYPE;
   signal BUFFER_WRITE_EN1     : std_logic;
   signal BUFFER_WRITE_PORT1   : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
   
   
   signal WRITE_ADDRESS_2 : BUFFER_ADDRESS_TYPE; 
   signal WRITE_EN_2 : std_logic; 
   
   signal R : std_logic_vector(31 downto 0);
   signal ctrl : std_logic_vector(7 downto 0); 
   signal finish : std_logic;
   
   component macc_ctrl is
   Port ( 
       clk, reset : in std_logic; 
       start : in std_logic; 
       
       input_addr : out buffer_address_type;
       input_en : out std_logic; 
       
       weight_addr : out weight_address_type;
       weight_en : out std_logic; 
       
       data_length : in std_logic_vector(10 downto 0);
       filter_size : in std_logic_vector(7 downto 0);
       all_finish : out std_logic; 
       ctrl : out std_logic_vector(7 downto 0)
   );
   end component;
   
   signal R_arr : BYTE_ARRAY_TYPE(0 to 4-1);
   signal finish_write_en : std_logic_vector(3 downto 0); 
   signal addr_out_int : integer := 0; 
   signal all_finish : std_logic; 
   signal all_finish_delay1, all_finish_delay2, all_finish_delay3 : std_logic; 
   signal all_finish_delay4, all_finish_delay5, all_finish_delay6 : std_logic; 
   signal addr_out_read_port_arr :BYTE_ARRAY_TYPE(0 to 4-1); 
   
begin


WEIGHT_BUFFER_i : WEIGHT_BUFFER
    generic map(
        MATRIX_WIDTH    => MATRIX_WIDTH,
        TILE_WIDTH      => WEIGHT_BUFFER_DEPTH
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,
        ENABLE          => ENABLE,
            
        -- Port0    
        ADDRESS0        => WEIGHT_ADDRESS0,
        EN0             => WEIGHT_EN0,
        WRITE_EN0       => '0',
        WRITE_PORT0     => (others => (others => '0')),
        READ_PORT0      => WEIGHT_READ_PORT0,
        -- Port1    
        ADDRESS1        => WEIGHT_ADDRESS,
        EN1             => WEIGHT_ENABLE,
        WRITE_EN1       => WEIGHT_WRITE_ENABLE,
        WRITE_PORT1     => WEIGHT_WRITE_PORT,
        READ_PORT1      => open
    );
    
    UNIFIED_BUFFER_i : UNIFIED_BUFFER
    generic map(
        MATRIX_WIDTH    => MATRIX_WIDTH,
        TILE_WIDTH      => UNIFIED_BUFFER_DEPTH
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,
        ENABLE          => ENABLE,
        
        -- Master port - overrides other ports
        MASTER_ADDRESS      => BUFFER_ADDRESS,
        MASTER_EN           => BUFFER_ENABLE,
        MASTER_WRITE_EN     => BUFFER_WRITE_ENABLE,
        MASTER_WRITE_PORT   => BUFFER_WRITE_PORT,
        MASTER_READ_PORT    => BUFFER_READ_PORT,
        -- Port0
        ADDRESS0        => BUFFER_ADDRESS0,
        EN0             => BUFFER_EN0,
        READ_PORT0      => BUFFER_READ_PORT0,
        -- Port1
        ADDRESS1        => WRITE_ADDRESS_2,
        EN1             => WRITE_EN_2, -- WRITE_EN_2
        WRITE_EN1       => WRITE_EN_2,
        WRITE_PORT1     => BUFFER_WRITE_PORT --
    );

    buffer_read_port0_vec <= BYTE_ARRAY_TO_BITS(BUFFER_READ_PORT0);
    weight_read_port0_vec <= BYTE_ARRAY_TO_BITS(WEIGHT_READ_PORT0);
    
    macc_conv_pe: macc_pe 
    Port map (
        clk => clk, 
        reset => reset,
        A => buffer_read_port0_vec,
        B => weight_read_port0_vec, 
        R => R, 
        filter_size => filter_size,
        finish => finish, 
        ctrl => ctrl
     );
     
   macc_ctrl_i : macc_ctrl 
     Port map ( 
         clk => clk,
         reset => reset, 
         start => start, --: in std_logic; 
         
         input_addr => BUFFER_ADDRESS0, -- : out buffer_address_type;
         input_en => BUFFER_EN0, --: out std_logic; 
         
         weight_addr => WEIGHT_ADDRESS0, --: out weight_address_type;
         weight_en => WEIGHT_EN0, --: out std_logic; 
         
         data_length => data_length, 
         filter_size => filter_size, --: in std_logic_vector(7 downto 0);
         all_finish => all_finish, 
         ctrl => ctrl
     );  
     
     R_arr <= BITS_TO_BYTE_ARRAY(R);
     finish_write_en <= "1111" when finish = '1' else "0000"; 
     
     process(clk, reset) is begin
     if clk'event and clk='1' then
        all_finish_delay1 <= all_finish; 
        all_finish_delay2 <= all_finish_delay1;
        all_finish_delay3 <= all_finish_delay2;
        all_finish_delay4 <= all_finish_delay3;
        all_finish_delay5 <= all_finish_delay4;
     end if; 
     end process;
     
     process(CLK, RESET) is begin
     if clk'event and clk='1' then
        if finish='1' then
            addr_out_int <= addr_out_int + 1; 
        end if; 
        if all_finish_delay2 = '1' then
            addr_out_int <= 0;
        end if; 
         
     end if; 
     end process;
     
  OUTPUT_BUFFER_i : UNIFIED_BUFFER
     generic map(
         MATRIX_WIDTH    => 1*4,
         TILE_WIDTH      => UNIFIED_BUFFER_DEPTH
     )
     port map(
         CLK             => CLK,
         RESET           => RESET,
         ENABLE          => ENABLE,
         
         -- Master port - overrides other ports
         MASTER_ADDRESS      => BUFFER_ADDRESS,
         MASTER_EN           => finish,
         MASTER_WRITE_EN     => finish_write_en,
         MASTER_WRITE_PORT   => R_arr,
         MASTER_READ_PORT    => open,
         -- Port0
         ADDRESS0        => addr_out_read,
         EN0             => addr_out_en0,
         READ_PORT0      => addr_out_read_port_arr,
         -- Port1
         ADDRESS1        => (others=>'0'),
         EN1             => '0', 
         WRITE_EN1       => '0',
         WRITE_PORT1     => R_arr --
     );
     addr_out_read_port <= BYTE_ARRAY_TO_BITS(addr_out_read_port_arr); 
     dp_to_dma_start <= all_finish_delay5;
end Behavioral;
