--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: dmux1_2_r.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: Гармонь
--Purpose:	dmux1_2_r - демультиплексор 1:2 с регистровым выходом
--
--Dependencies:
--
--Reference:
--
--Revision History:
--	Revision 0.1.0 (23/09/2011) - Первая версия
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dmux1_2_r is
  port (
	clk    : in  std_logic;
	i_stb  : in  std_logic;
	i_addr : in  std_logic;
	i_dat  : in  std_logic;
	o_stb  : out std_logic_vector(1 downto 0);
	o_dat  : out std_logic_vector(1 downto 0)
  );
end dmux1_2_r;

architecture syn of dmux1_2_r is
  
  signal ostb : std_logic_vector(1 downto 0);
  signal odat : std_logic_vector(1 downto 0);
  
begin

  dmux_prc: process(clk)
  begin
	if(rising_edge(clk))then
		if(i_stb = '1')then
			if(i_addr = '0')then
				ostb <= b"01";
			else
				ostb <= b"10";
			end if;
		else
			ostb <= b"00";
		end if;
		odat <= i_dat & i_dat;
	end if;
  end process;
  
  o_stb <= ostb;
  o_dat <= odat;

end syn;
