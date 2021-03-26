use WORK.TPU_pack.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity macc_ctrl_tb is
end macc_ctrl_tb;

architecture Behavioral of macc_ctrl_tb is
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
    ctrl : out std_logic_vector(7 downto 0)
);
end component;

signal clk, reset : std_logic; 
signal start : std_logic; 
signal input_addr : buffer_address_type;
signal weight_addr : weight_address_type; 
signal input_en : std_logic;
signal weight_en : std_logic; 
signal filter_size : std_logic_vector(7 downto 0); 
signal ctrl : std_logic_vector(7 downto 0); 
signal data_length : std_logic_vector(10 downto 0);

constant clock_period   : time := 10 ns;

begin

macc_ctrl_dut : macc_ctrl 
Port map ( 
    clk => clk,
    reset => reset, 
    start => start, --: in std_logic; 
    
    input_addr => input_addr, -- : out buffer_address_type;
    input_en => input_en, --: out std_logic; 
    
    weight_addr => weight_addr, --: out weight_address_type;
    weight_en => weight_en, --: out std_logic; 
    
    data_length => data_length, 
    filter_size => filter_size, --: in std_logic_vector(7 downto 0);
    ctrl => ctrl-- : out std_logic_vector(7 downto 0)
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

STIMULUS: process is begin
    reset <= '1';
    wait for 5*clock_period; 
    reset <= '0';
    start <= '1';
    filter_size <= x"04";
    data_length <= "00000001111";
    wait for clock_period; 
    start <= '0';
    wait; 
end process;

end Behavioral;
