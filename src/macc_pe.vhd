library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.TPU_pack.all;
use IEEE.NUMERIC_STD.ALL;


entity macc_pe is
Port (
    clk, reset : in std_logic; 
    A : in std_logic_vector(7 downto 0);
    B : in std_logic_vector(7 downto 0);
    R : out std_logic_vector(31 downto 0);
    filter_size : in std_logic_vector(7 downto 0); 
    finish : out std_logic; 
    ctrl : in std_logic_vector(7 downto 0)
 );
end macc_pe;

architecture Behavioral of macc_pe is

signal r_reg, r_next : std_logic_vector(31 downto 0); 
signal result_mul : std_logic_vector(31 downto 0); 
signal result_mul_int : integer range 0 to 65535 := 0; 
signal result_mul_add_int : integer := 0;

signal A_sig, B_sig : std_logic_vector(7 downto 0); 
signal round, round2  : unsigned(7 downto 0); 
signal finish_temp : std_logic;

signal ctrl_temp2, ctrl_temp, ctrl_temp3 : std_logic_vector(7 downto 0);

begin

-- combination_process
process(A_sig, B_sig, result_mul_int, result_mul, r_reg) is begin
    result_mul_int <= to_integer(unsigned(A_sig)) * to_integer(unsigned(B_sig));
    result_mul <= std_logic_vector(to_unsigned(result_mul_int, result_mul'length));
    result_mul_add_int <= to_integer(unsigned(result_mul)) + to_integer(unsigned(r_reg));
end process;



process(clk,reset) is begin
    if clk'event and clk='1' then
        if reset = '1' then
            r_reg <= (others=> '0');
            A_sig <= (others=>'0'); 
            B_sig <= (others=>'0'); 
            finish_temp <= '0';
            round <= to_unsigned(0, round'length);
            round2 <= to_unsigned(0, round'length);
        else 
            A_sig <= A; 
            B_sig <= B;  
            finish_temp <= '0';
            if ctrl_temp2(0) = '1' then
                round <= round + 1; 
                round2 <= round2 + 1; 
                r_reg <= std_logic_vector(to_unsigned(result_mul_add_int, r_next'length));
                if round = unsigned(filter_size)-1 then
--                   r_reg <= (others=> '0');
                   round <= to_unsigned(0, round'length);
                   finish_temp <= '1';
                end if;    
                if round2 = unsigned(filter_size) then
                    round2 <= to_unsigned(1, round'length);
                    r_reg <= (others=> '0');
--                    finish <= '1';
                end if;    
            end if; 
  
        end if;
    end if; 
end process;


process(clk,reset) is begin
if clk'event and clk='1' then
    R <= std_logic_vector(to_unsigned(result_mul_add_int, r_next'length));
end if; 
end process;

process(clk,reset) is begin
if clk'event and clk='1' then
    finish <= finish_temp;
end if; 
end process;

process(clk, reset) is begin
if clk'event and clk='1' then
    ctrl_temp <= ctrl;
    ctrl_temp2 <= ctrl_temp; 
    ctrl_temp3 <= ctrl_temp2; 
       
end if ;
end process;
             


end Behavioral;
