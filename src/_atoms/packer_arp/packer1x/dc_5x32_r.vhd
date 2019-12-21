--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: dc_5x32_r.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: Гармонь
--Purpose:	dc_5x32_r - дешифратор 5х32 с регистровым выходом
--
--
--Dependencies: 
--
--
--Reference:
--Revision History:
--	Revision 0.1.0 (19/09/2011) - Первая версия
--	Revision 0.1.1 (20/09/2011) - Добавлен параметр OREG
--	Revision 0.1.2 (22/09/2011) - Избавились от latches в асинхронном процессе
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dc_5x32_r is
  generic (
	OREG   : boolean := false
  );
  port (
	clk    : in  std_logic;
	input  : in  std_logic_vector(4  downto 0);
	output : out std_logic_vector(31 downto 0)
  );
end dc_5x32_r;

architecture syn of dc_5x32_r is

  signal s_output : std_logic_vector(31 downto 0) := (others=>'0');

begin

  dc_prc: process(input)
  begin
	case input is
		when b"00000" => s_output <= b"00000000000000000000000000000001";
		when b"00001" => s_output <= b"00000000000000000000000000000010";
		when b"00010" => s_output <= b"00000000000000000000000000000100";
		when b"00011" => s_output <= b"00000000000000000000000000001000";
		when b"00100" => s_output <= b"00000000000000000000000000010000";
		when b"00101" => s_output <= b"00000000000000000000000000100000";
		when b"00110" => s_output <= b"00000000000000000000000001000000";
		when b"00111" => s_output <= b"00000000000000000000000010000000";
		when b"01000" => s_output <= b"00000000000000000000000100000000";
		when b"01001" => s_output <= b"00000000000000000000001000000000";
		when b"01010" => s_output <= b"00000000000000000000010000000000";
		when b"01011" => s_output <= b"00000000000000000000100000000000";
		when b"01100" => s_output <= b"00000000000000000001000000000000";
		when b"01101" => s_output <= b"00000000000000000010000000000000";
		when b"01110" => s_output <= b"00000000000000000100000000000000";
		when b"01111" => s_output <= b"00000000000000001000000000000000";
		when b"10000" => s_output <= b"00000000000000010000000000000000";
		when b"10001" => s_output <= b"00000000000000100000000000000000";
		when b"10010" => s_output <= b"00000000000001000000000000000000";
		when b"10011" => s_output <= b"00000000000010000000000000000000";
		when b"10100" => s_output <= b"00000000000100000000000000000000";
		when b"10101" => s_output <= b"00000000001000000000000000000000";
		when b"10110" => s_output <= b"00000000010000000000000000000000";
		when b"10111" => s_output <= b"00000000100000000000000000000000";
		when b"11000" => s_output <= b"00000001000000000000000000000000";
		when b"11001" => s_output <= b"00000010000000000000000000000000";
		when b"11010" => s_output <= b"00000100000000000000000000000000";
		when b"11011" => s_output <= b"00001000000000000000000000000000";
		when b"11100" => s_output <= b"00010000000000000000000000000000";
		when b"11101" => s_output <= b"00100000000000000000000000000000";
		when b"11110" => s_output <= b"01000000000000000000000000000000";
		when b"11111" => s_output <= b"10000000000000000000000000000000";
		when others   => s_output <= b"00000000000000000000000000000000";
	end case;
  end process;
  
  --==================================================
  -- Output
  oreg_true_gen: if (OREG = true) generate
	signal reg : std_logic_vector(31 downto 0) := (others=>'0');
  begin
	out_prc: process(clk)
	begin
		if(rising_edge(clk))then
			reg <= s_output;
		end if;
	end process;
	output <= reg;
  end generate;
  
  oreg_false_gen: if (OREG = false) generate
	output <= s_output;
  end generate;
  
end syn;
