use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity conv_top_tb is
end conv_top_tb;

architecture Behavioral of conv_top_tb is

component conv_top is
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
end component;
signal clk, reset          :  std_logic;
signal ENABLE              :  std_logic;

signal conv_start               : std_logic; 
signal data_length         : std_logic_vector(10 downto 0); 
signal filter_size         : std_logic_vector(7 downto 0); 

constant MATRIX_WIDTH : integer  := 1; 

signal WEIGHT_WRITE_PORT   :  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the weight buffer
signal WEIGHT_ADDRESS      :  WEIGHT_ADDRESS_TYPE; --!< Host address for the weight buffer.
signal WEIGHT_ENABLE       :  std_logic; --!< Host enable for the weight buffer.
signal WEIGHT_WRITE_ENABLE :  std_logic_vector(0 to MATRIX_WIDTH-1); --!< Host write enable for the weight buffer.

signal BUFFER_WRITE_PORT   :  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host write port for the unified buffer.
signal BUFFER_READ_PORT    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1); --!< Host read port for the unified buffer.
signal BUFFER_ADDRESS      :  BUFFER_ADDRESS_TYPE; --!< Host address for the unified buffer.
signal BUFFER_ENABLE       :  std_logic; --!< Host enable for the unified buffer.
signal BUFFER_WRITE_ENABLE :  std_logic_vector(0 to MATRIX_WIDTH-1); --!< Host write enable for the unified buffer.

constant clock_period   : time := 10 ns;
signal START            : boolean;

type WEIGHT_ARRAY_TYPE is array(0 to 4) of integer;
constant weight_size : integer := 5;
constant weight_ram :  WEIGHT_ARRAY_TYPE := (1,2,3,4,5);

type INPUT_ARRAY_TYPE is array(0 to 19) of integer;
constant input_size : integer := 20;
constant input_ram : INPUT_ARRAY_TYPE :=  (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20);

begin

DUT_i : conv_top
generic map(
    MATRIX_WIDTH      => 1 , --     : natural := 1; --!< The width of the Matrix Multiply Unit and busses.
    WEIGHT_BUFFER_DEPTH => 1024, --    : natural := 1024; --!< The depth of the weight buffer.
    UNIFIED_BUFFER_DEPTH => 4096 --   : natural := 4096 --!< The depth of the unified buffer.
)
Port map(
    CLK => clk,
    RESET => reset, 
    ENABLE => enable, 
    
    start => conv_start, 
    data_length => data_length, 
    filter_size => filter_size,
    
    
    WEIGHT_WRITE_PORT  => WEIGHT_WRITE_PORT,
    WEIGHT_ADDRESS      => WEIGHT_ADDRESS,
    WEIGHT_ENABLE      => WEIGHT_ENABLE,
    WEIGHT_WRITE_ENABLE => WEIGHT_WRITE_ENABLE,
    
    BUFFER_WRITE_PORT   => BUFFER_WRITE_PORT,
    BUFFER_READ_PORT    => BUFFER_READ_PORT,
    BUFFER_ADDRESS     => BUFFER_ADDRESS,
    BUFFER_ENABLE       => BUFFER_ENABLE,
    BUFFER_WRITE_ENABLE => BUFFER_WRITE_ENABLE
);

CLOCK_GEN: 
process
begin
 while not false loop
   CLK <= '0', '1' after clock_period / 2;
   wait for clock_period;
 end loop;
 wait;
end process CLOCK_GEN; 

STIMULUS: process is
    begin
    conv_start <= '0';
    filter_size <= x"05";
    data_length <= "00000010100";
    BUFFER_WRITE_ENABLE <= "0";
    BUFFER_WRITE_PORT <= (others => (others => '0'));
    BUFFER_ENABLE <= '0';
    BUFFER_ADDRESS <= (others => '0');
    wait until '1'=CLK and CLK'event;
    RESET <= '1';
    wait until '1'=CLK and CLk'event;
    RESET <= '0';
    enable <= '1';
    -- begin fetch data to RAM
    -- begin here

    
    -- Load input 0
    BUFFER_ENABLE <= '1';
    BUFFER_WRITE_ENABLE <= "1";
    for i in 0 to input_size-1 loop
        report "i=" & integer'image(i);
        BUFFER_ADDRESS <= std_logic_vector(to_unsigned(i, 12));
        BUFFER_WRITE_PORT(0) <= (std_logic_vector(to_unsigned(input_ram(i), BYTE_WIDTH)));
        wait until '1'=CLK and CLk'event;
    end loop;
    wait until '1'=CLK and CLK'event;
    BUFFER_WRITE_ENABLE <= "0";
    -- end here
    BUFFER_ENABLE <= '0';
    WEIGHT_ENABLE <= '1';
    WEIGHT_WRITE_ENABLE <= "1";
    for i in 0 to weight_size-1 loop
        WEIGHT_ADDRESS <= std_logic_vector(to_unsigned(i, 15));
        WEIGHT_WRITE_PORT(0) <= (std_logic_vector(to_unsigned(weight_ram(i), BYTE_WIDTH)));
        wait until '1'=CLK and CLk'event;
    end loop;
    wait until '1'=CLK and CLk'event;
    WEIGHT_WRITE_ENABLE <= "0";
    WEIGHT_ENABLE <= '0';
    
    conv_start <= '1';
    wait until '1'=CLK and CLk'event;
    conv_start <= '0';
    wait; 
end process;





end Behavioral;
