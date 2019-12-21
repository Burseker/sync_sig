--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: cd_32x5_r.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: Гармонь
--Purpose:	cd_32x5_r - шифратор 32х5 с регистровым выходом
--
--
--Dependencies: 
--
--
--Reference:
--Revision History:
--	Revision 0.1.0 (19/09/2011) - Первая версия
--	Revision 0.1.1 (20/09/2011) - Добавлен параметр OREG
--	Revision 0.1.2 (22/09/2011) - latches
--		* Избавились от latches в асинхронном процессе
--	Revision 0.2.0 (28/09/2011) - Вторая версия
--		* Ресурсов занимает значительно меньше
--		* Изменили реализацию вместо case
--		  на логическую функцию шифратора
--		- Убрали параметр OREG, теперь всегда
--		  регистровый выход
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cd_32x5_r is
  port (
	clk    : in  std_logic;
	input  : in  std_logic_vector(31 downto 0);
	output : out std_logic_vector(4  downto 0)
  );
end cd_32x5_r;

architecture syn of cd_32x5_r is

  signal s_output : std_logic_vector(4 downto 0) := (others=>'0');
  
begin

  cd_prc: process(clk)
  begin
  	if(rising_edge(clk))then
		s_output(0) <= input(1)  or input(3)  or input(5)  or input(7)  or input(9)  or input(11) or input(13) or input(15) or input(17) or input(19) or input(21) or input(23) or input(25) or input(27) or input(29) or input(31);
		s_output(1) <= input(2)  or input(3)  or input(6)  or input(7)  or input(10) or input(11) or input(14) or input(15) or input(18) or input(19) or input(22) or input(23) or input(26) or input(27) or input(30) or input(31);
		s_output(2) <= input(4)  or input(5)  or input(6)  or input(7)  or input(12) or input(13) or input(14) or input(15) or input(20) or input(21) or input(22) or input(23) or input(28) or input(29) or input(30) or input(31);
		s_output(3) <= input(8)  or input(9)  or input(10) or input(11) or input(12) or input(13) or input(14) or input(15) or input(24) or input(25) or input(26) or input(27) or input(28) or input(29) or input(30) or input(31);
		s_output(4) <= input(16) or input(17) or input(18) or input(19) or input(20) or input(21) or input(22) or input(23) or input(24) or input(25) or input(26) or input(27) or input(28) or input(29) or input(30) or input(31);
	end if;
  end process;
  
  output <= s_output;
	
end syn;


  -- СТАРАЯ РЕАЛИЗАЦИЯ (Revision 0.1.2)
  -- cd_prc: process(input)
  -- begin
	-- case input is
		-- when b"00000000000000000000000000000001" => s_output <= b"00000";
		-- when b"00000000000000000000000000000010" => s_output <= b"00001";
		-- when b"00000000000000000000000000000100" => s_output <= b"00010";
		-- when b"00000000000000000000000000001000" => s_output <= b"00011";
		-- when b"00000000000000000000000000010000" => s_output <= b"00100";
		-- when b"00000000000000000000000000100000" => s_output <= b"00101";
		-- when b"00000000000000000000000001000000" => s_output <= b"00110";
		-- when b"00000000000000000000000010000000" => s_output <= b"00111";
		-- when b"00000000000000000000000100000000" => s_output <= b"01000";
		-- when b"00000000000000000000001000000000" => s_output <= b"01001";
		-- when b"00000000000000000000010000000000" => s_output <= b"01010";
		-- when b"00000000000000000000100000000000" => s_output <= b"01011";
		-- when b"00000000000000000001000000000000" => s_output <= b"01100";
		-- when b"00000000000000000010000000000000" => s_output <= b"01101";
		-- when b"00000000000000000100000000000000" => s_output <= b"01110";
		-- when b"00000000000000001000000000000000" => s_output <= b"01111";
		-- when b"00000000000000010000000000000000" => s_output <= b"10000";
		-- when b"00000000000000100000000000000000" => s_output <= b"10001";
		-- when b"00000000000001000000000000000000" => s_output <= b"10010";
		-- when b"00000000000010000000000000000000" => s_output <= b"10011";
		-- when b"00000000000100000000000000000000" => s_output <= b"10100";
		-- when b"00000000001000000000000000000000" => s_output <= b"10101";
		-- when b"00000000010000000000000000000000" => s_output <= b"10110";
		-- when b"00000000100000000000000000000000" => s_output <= b"10111";
		-- when b"00000001000000000000000000000000" => s_output <= b"11000";
		-- when b"00000010000000000000000000000000" => s_output <= b"11001";
		-- when b"00000100000000000000000000000000" => s_output <= b"11010";
		-- when b"00001000000000000000000000000000" => s_output <= b"11011";
		-- when b"00010000000000000000000000000000" => s_output <= b"11100";
		-- when b"00100000000000000000000000000000" => s_output <= b"11101";
		-- when b"01000000000000000000000000000000" => s_output <= b"11110";
		-- when b"10000000000000000000000000000000" => s_output <= b"11111";
		-- when others                              => s_output <= b"00000";
	-- end case;
  -- end process;
  
  -- --==================================================
  -- -- Output
  -- oreg_true_gen: if (OREG = true) generate
	-- signal reg : std_logic_vector(4 downto 0) := (others=>'0');
  -- begin
	-- out_prc: process(clk)
	-- begin
		-- if(rising_edge(clk))then
			-- reg <= s_output;
		-- end if;
	-- end process;
	-- output <= reg;
  -- end generate;
  
  -- oreg_false_gen: if (OREG = false) generate
	-- output <= s_output;
  -- end generate;