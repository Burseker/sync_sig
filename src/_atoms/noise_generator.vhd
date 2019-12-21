--================================================================================
-- Description: FPGA noise generator
-- Version:     0.1.0
-- Developer:   SVB, NNP
-- Workgroup:   IRS16
--================================================================================
----------------------------------------------------------------------------------
-- Keywords:    
-- Tools:       Altera Quartus 9.1 SP1
--             
-- Details:    
-- Ver 0.0.0 - File created 
-- Ver 0.1.0 - Параметры INIT_STATE используются как входные портры.
-- 
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;

--use work.other_components_pkg.all;

entity noise_generator is
generic(NUMBER_BITS   : integer:=12; -- signal to noise ratio
        DATA_WIDTH    : integer:=13;
        POLINOM_ORDER : integer:=25;
        INIT_STATE1   : integer:=1234; 
        INIT_STATE2   : integer:=3456; 
        INIT_STATE3   : integer:=5678       
        );
port
(
  clk                           : in std_logic;
  rst                           : in std_logic;
  init_st1                      : in std_logic_vector(31 downto 0) := conv_std_logic_vector(INIT_STATE1,32);
  init_st2                      : in std_logic_vector(31 downto 0) := conv_std_logic_vector(INIT_STATE2,32);
  init_st3                      : in std_logic_vector(31 downto 0) := conv_std_logic_vector(INIT_STATE3,32);
  num_bits                      : in std_logic_vector(3 downto 0);
  ena                           : in std_logic;  
  sample                        : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end noise_generator;

architecture impl of noise_generator is
 
    signal s_first_PNS  : std_logic_vector(POLINOM_ORDER-1 downto 0) := conv_std_logic_vector(INIT_STATE1,POLINOM_ORDER);
    signal s_second_PNS : std_logic_vector(POLINOM_ORDER-1 downto 0) := conv_std_logic_vector(INIT_STATE2,POLINOM_ORDER);
    signal s_thrid_PNS  : std_logic_vector(POLINOM_ORDER-1 downto 0) := conv_std_logic_vector(INIT_STATE3,POLINOM_ORDER);
    signal s_first      : std_logic_vector(DATA_WIDTH+1 downto 0) := (Others=>'0');
    signal s_second     : std_logic_vector(DATA_WIDTH+1 downto 0) := (Others=>'0');
    signal s_thrid      : std_logic_vector(DATA_WIDTH+1 downto 0) := (Others=>'0');
    
    signal s_osum1      : std_logic_vector(DATA_WIDTH+1 downto 0) := (Others=>'0');
    signal s_osum2      : std_logic_vector(DATA_WIDTH+1 downto 0) := (Others=>'0');
  
    signal s_osample       : std_logic_vector(DATA_WIDTH-1 downto 0) := (Others=>'0');
begin

--===================================
-- PNS generators
--===================================
    -- 10000100000000000000101001
    first_PNS : process(clk,rst)
    variable i : integer;
    begin
        if(rst='1') then
           s_first_PNS <= init_st1(POLINOM_ORDER-1 downto 0);
        else
           if(rising_edge(clk)) then
              if(ena='1') then
                 for i in POLINOM_ORDER-1 downto 1 loop
                    s_first_PNS(i)<=s_first_PNS(i-1);
                 end loop;
                 s_first_PNS(0)<=(s_first_PNS(POLINOM_ORDER-1) xor s_first_PNS(20) xor s_first_PNS(5) xor s_first_PNS(3) xor s_first_PNS(0));
              end if;
           end if;
        end if;
    end process;
    
    -- 10000000000000101101011101
    second_PNS : process(clk,rst)
    variable i : integer;
    begin
        if(rst='1') then
           s_second_PNS <= init_st2(POLINOM_ORDER-1 downto 0);
        else
           if(rising_edge(clk)) then
              if(ena='1') then
                 for i in POLINOM_ORDER-1 downto 1 loop
                    s_second_PNS(i)<=s_second_PNS(i-1);
                 end loop;
                 s_second_PNS(0)<=(s_second_PNS(POLINOM_ORDER-1) xor s_second_PNS(11) xor s_second_PNS(9) xor s_second_PNS(8) xor s_second_PNS(6) xor s_second_PNS(4) xor s_second_PNS(3) xor s_second_PNS(2) xor s_second_PNS(0));
              end if;
           end if;
        end if;
    end process;
    
    -- 10000000000000000000001001
    thrid_PNS : process(clk,rst)
    variable i : integer;
    begin
        if(rst='1') then
           s_thrid_PNS <= init_st3(POLINOM_ORDER-1 downto 0);
        else
           if(rising_edge(clk)) then
              if(ena='1') then
                 for i in POLINOM_ORDER-1 downto 1 loop
                    s_thrid_PNS(i)<=s_thrid_PNS(i-1);
                 end loop;
                 s_thrid_PNS(0)<=(s_thrid_PNS(POLINOM_ORDER-1) xor s_thrid_PNS(3) xor s_thrid_PNS(0));
              end if;
           end if;
        end if;
    end process;
    
--===================================
-- sum
--===================================  
    s_first(DATA_WIDTH+1 downto NUMBER_BITS) <= (others => s_first_PNS(NUMBER_BITS-1));
    s_first(NUMBER_BITS-1 downto 0)          <= s_first_PNS(NUMBER_BITS-1 downto 0);
    
    s_second(DATA_WIDTH+1 downto NUMBER_BITS) <= (others => s_second_PNS(NUMBER_BITS-1));
    s_second(NUMBER_BITS-1 downto 0)          <= s_second_PNS(NUMBER_BITS-1 downto 0);
    
    s_thrid(DATA_WIDTH+1 downto NUMBER_BITS+1) <= (others => s_thrid_PNS(NUMBER_BITS));
    s_thrid(NUMBER_BITS downto 0)          <= s_thrid_PNS(NUMBER_BITS downto 0);
    
    process(clk,rst)
    begin
        if(rst = '1')then
            s_osum1 <= (others =>'0');
            s_osum2 <= (others =>'0');
        elsif(rising_edge(clk))then
            if(ena='1') then
                s_osum1 <= s_first + s_second;
                s_osum2 <= s_osum1 + s_thrid;
            end if;    
        end if;
    end process;
    
--===================================
-- select
--===================================
    process(clk,rst)
    begin   
        if(rst = '1')then
            s_osample <= (others => '0');
        elsif(rising_edge(clk))then
            if(ena='1') then
                case num_bits is
                    when "0001" =>
                        l0: for i in 0 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(0);
                        end loop;
                    when "0010" =>                    
                        l1: for i in 1 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(1);
                        end loop;
                        s_osample(0) <= s_osum2(0);                    
                    when "0011" =>
                        l2: for i in 2 to DATA_WIDTH-1 loop
                                s_osample(i) <=  s_osum2(2);
                            end loop;
                        s_osample(1 downto 0) <= s_osum2(1 downto 0);
                    when "0100" =>
                        l3: for i in 3 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(3);
                        end loop;
                        s_osample(2 downto 0) <=s_osum2(2 downto 0);
                    when "0101" =>
                         l4: for i in 4 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(4);
                        end loop;
                        s_osample(3 downto 0) <=s_osum2(3 downto 0);
                    when "0110" =>
                        l5: for i in 5 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(5);
                        end loop;
                        s_osample(4 downto 0) <= s_osum2(4 downto 0);
                    when "0111" =>
                        l6: for i in 6 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(6);
                        end loop;
                        s_osample(5 downto 0) <= s_osum2(5 downto 0);
                    when "1000" =>
                        l7: for i in 7 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(7);
                        end loop;
                        s_osample(6 downto 0) <= s_osum2(6 downto 0);
                    when "1001" =>
                        l8: for i in 8 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(8);
                        end loop;
                        s_osample(7 downto 0) <= s_osum2(7 downto 0);
                    when "1010" =>
                        l9: for i in 9 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(9);
                        end loop;
                        s_osample(8 downto 0) <= s_osum2(8 downto 0);    
                    when "1011" =>
                        l10: for i in 10 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(10);
                        end loop;
                        s_osample(9 downto 0) <= s_osum2(9 downto 0);
                    when "1100" =>
                        l11: for i in 11 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(11);
                        end loop;
                        s_osample(10 downto 0) <= s_osum2(10 downto 0);
                    when "1101" =>
                        l12: for i in 12 to DATA_WIDTH-1 loop
                            s_osample(i) <=  s_osum2(12);
                        end loop;
                        s_osample(11 downto 0) <= s_osum2(11 downto 0);
                    when others =>   
                        s_osample <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    sample <= s_osample;
    
    
    
end impl;
