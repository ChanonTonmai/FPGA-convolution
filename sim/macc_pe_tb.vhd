library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity macc_pe_tb is
end macc_pe_tb;

architecture Behavioral of macc_pe_tb is
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
    
    constant clock_period   : time := 10 ns;
    
    signal clk, reset : std_logic; 
    signal A : std_logic_vector(7 downto 0);
    signal B : std_logic_vector(7 downto 0);
    signal R : std_logic_vector(31 downto 0);
    signal ctrl : std_logic_vector(7 downto 0);
    signal finish : std_logic; 
    signal filter_size : std_logic_vector(7 downto 0);
    
    
begin

    DUT: macc_pe 
    Port map (
        clk => clk, 
        reset => reset,
        A => A,
        B => B, 
        R => R, 
        filter_size => filter_size,
        finish => finish, 
        ctrl => ctrl
     );

    STIMULUS:
    process is begin
        reset <= '1';
        wait for 5*clock_period; 
        filter_size <= x"04";
        reset <= '0';
        wait for clock_period; 
        A <= std_logic_vector(to_unsigned(15, A'length));
        B <= std_logic_vector(to_unsigned(10, A'length));
        ctrl <= x"01";
        wait for clock_period; 
        A <= std_logic_vector(to_unsigned(12, A'length));
        B <= std_logic_vector(to_unsigned(13, A'length));
        ctrl <= x"01";
        wait for clock_period; 
        A <= std_logic_vector(to_unsigned(10, A'length));
        B <= std_logic_vector(to_unsigned(17, A'length));
        ctrl <= x"01";
        wait for clock_period; 
        A <= std_logic_vector(to_unsigned(15, A'length));
        B <= std_logic_vector(to_unsigned(10, A'length));
        ctrl <= x"01";
        wait for clock_period; 
        A <= std_logic_vector(to_unsigned(12, A'length));
        B <= std_logic_vector(to_unsigned(13, A'length));
        ctrl <= x"01";
        wait for clock_period; 
        A <= std_logic_vector(to_unsigned(10, A'length));
        B <= std_logic_vector(to_unsigned(17, A'length));
        ctrl <= x"01";
        wait for clock_period; 
        ctrl <= x"00";

        wait;
        
    end process STIMULUS;  
       CLOCK_GEN: 
    process
    begin
        while not false loop
          CLK <= '0', '1' after clock_period / 2;
          wait for clock_period;
        end loop;
        wait;
    end process CLOCK_GEN; 
    
end Behavioral;
