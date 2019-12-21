--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: mux32_1_r.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: Гармонь
--Purpose:	mux32_1_r - мультиплексор 32:1 с регистровым выходом
--
--
--Dependencies: 
--
--
--Reference:
--Revision History:
--	Revision 0.1.0 (19/09/2011) - Первая версия
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mux32_1_r is
  port (
	clk    : in  std_logic;
	addr   : in  std_logic_vector(4  downto 0);
	input  : in  std_logic_vector(31 downto 0);
	output : out std_logic
  );
end mux32_1_r;

architecture syn of mux32_1_r is

  signal int_addr : integer range 0 to 2**5-1 := 0;
  
begin
  
  int_addr <= to_integer(unsigned(addr));
  
  mux_prc: process(clk)
  begin
	if(rising_edge(clk))then
		case int_addr is
			when 0  => output <= input(0);
			when 1  => output <= input(1);
			when 2  => output <= input(2);
			when 3  => output <= input(3);
			when 4  => output <= input(4);
			when 5  => output <= input(5);
			when 6  => output <= input(6);
			when 7  => output <= input(7);
			when 8  => output <= input(8);
			when 9  => output <= input(9);
			when 10 => output <= input(10);
			when 11 => output <= input(11);
			when 12 => output <= input(12);
			when 13 => output <= input(13);
			when 14 => output <= input(14);
			when 15 => output <= input(15);
			when 16 => output <= input(16);
			when 17 => output <= input(17);
			when 18 => output <= input(18);
			when 19 => output <= input(19);
			when 20 => output <= input(20);
			when 21 => output <= input(21);
			when 22 => output <= input(22);
			when 23 => output <= input(23);
			when 24 => output <= input(24);
			when 25 => output <= input(25);
			when 26 => output <= input(26);
			when 27 => output <= input(27);
			when 28 => output <= input(28);
			when 29 => output <= input(29);
			when 30 => output <= input(30);
			when 31 => output <= input(31);
			when others => NULL;
		end case;
	end if;
  end process;
  
end syn;
