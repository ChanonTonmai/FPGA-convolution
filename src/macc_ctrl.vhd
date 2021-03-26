library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.TPU_pack.all;

entity macc_ctrl is
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
end macc_ctrl;

architecture Behavioral of macc_ctrl is
    type state_type is (idle, send_data, send_finish); 
    signal state : state_type;
    
    signal ctrl_tmp : std_logic_vector(7 downto 0); 
    signal input_addr_int : integer; 
    signal weight_addr_int : integer; 
    signal round : integer;
    signal round_num : integer; 
    
    signal input_en_temp, input_en_temp2, input_en_temp3 : std_logic; 
    
begin

input_addr <= std_logic_vector(to_unsigned(input_addr_int, input_addr'length));
weight_addr <= std_logic_vector(to_unsigned(weight_addr_int, weight_addr'length)); 
ctrl <= ctrl_tmp;
round_num <= to_integer(unsigned(data_length)) - to_integer(unsigned(filter_size)) ; 

input_en <= ctrl_tmp(0); 
weight_en <= ctrl_tmp(0);

process(clk) is begin 
if clk'event and clk='1' then
    if reset = '1' then
        state <= idle;
        all_finish <= '0';
        input_addr_int <= 0;
        weight_addr_int <= 0;
        ctrl_tmp <= x"00"; 
        round <= 0; 
    else 
        case state is 
            when idle =>
                all_finish <= '0';
                ctrl_tmp <= x"00"; 
                input_addr_int <= 0;
                weight_addr_int <= 0;
                round <= 0;
                if start = '1' then
                    ctrl_tmp <= x"01"; 
                    state <= send_data;
                else 
                    state <= idle;
                end if; 
                
            when send_data => 
                  ctrl_tmp <= x"01";
                  all_finish <= '0';
                  if weight_addr_int < to_integer(unsigned(filter_size))-1 then
                    weight_addr_int <= weight_addr_int + 1; 
                  else
                    round <= round + 1 ; 
                    weight_addr_int <= 0;
                  end if; 
                  if input_addr_int < to_integer(unsigned(filter_size))-1+round then
                    input_addr_int <= input_addr_int + 1; 
                  else 
                    input_addr_int <= round+1;
                  end if;
      
    
                  if round < round_num + to_integer(unsigned(data_length(0 downto 0)))then   
                    state <= send_data;
                  else
                    if input_addr_int < to_integer(unsigned(filter_size))-1+round then 
                        state <= send_data; 
                    else
                        ctrl_tmp <= x"00";
                        round <= 0;
                        input_addr_int <= 0;
                        weight_addr_int <= 0;
                        state <= send_finish;
                    end if; 
                  end if;  
            when send_finish =>
                all_finish <= '1';
                state <= idle;
                  
             when others => 
                state <= idle; 
                
          end case; 
      end if;
   end if; 
end process;     

process(clk, reset) is begin
if clk'event and clk='1' then
    input_en_temp <= ctrl_tmp(0);
    input_en_temp2 <= input_en_temp; 
    input_en_temp3 <= input_en_temp2; 
       
end if ;
end process;
             
                  
end Behavioral;
