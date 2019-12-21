--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: addr_cd.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: Гармонь
--Purpose:	addr_cd - шифратор адреса
--		Формирует адрес для мультиплексора flex_packer
--
--Dependencies:
--		* Поддержка OWIDTH = 32
--
--Reference:
--
--Revision History:
--	Revision 0.1.0 (22/09/2011) - Первая версия
--	Revision 0.1.1 (26/09/2011) - Выбор выходного регистра
--		+ Порт i_high выбор одного из двух выходных 
--		  регистров (необходим dmux1_2_r)
--		+ Порт o_high
--	Revision 0.1.2 (27/09/2011) - Разбили комбинационные цепи
--		+ Регистровый выход дешифратора cd_32x5_r
--		* Пришлось сделать задержку на 1 такт. Строб o_stb
--		  появится через такт после i_stb
--		+ Задержка i_high_r
--	Revision 0.1.3 (28/09/2011) - Новый cd_32x5_r
--		* Шифратор cd_32x5_r версии 0.2.0
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_packer1x.all;

entity addr_cd is
  generic (
	OWIDTH : integer := 32
  );
  port (
	clk    : in  std_logic;
	
	i_stb  : in  std_logic;
	i_high : in  std_logic_vector(OWIDTH-1 downto 0);
	i_addr : in  std_logic_vector(OWIDTH-1 downto 0);
	
	o_stb  : out std_logic;
	o_high : out std_logic;
	o_addr : out std_logic_vector(log2_ceil(OWIDTH)-1 downto 0) -- log2_ceil(32) - 1 = 4
  );
end addr_cd;

architecture syn of addr_cd is

  constant c_zeros : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  signal cd_input  : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal cd_output : std_logic_vector(log2_ceil(OWIDTH)-1 downto 0) := (others=>'0');
  signal oaddr     : std_logic_vector(log2_ceil(OWIDTH)-1 downto 0) := (others=>'0');
  signal i_high_r  : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal ohigh     : std_logic := '0';
  signal ostb      : std_logic := '0';
  signal ostb_r    : std_logic := '0';
  
begin

  --==================================================
  -- Задержка
  idel_prc: process(clk)
  begin
	if(rising_edge(clk))then
		i_high_r <= i_high;
	end if;
  end process;
  
  
  --==================================================
  -- Шифратор
  cd_input <= i_addr;
  
  ow_32_gen: if (OWIDTH = 32) generate
	u_cd32x5: cd_32x5_r
	PORT MAP(
		clk    => clk,
		input  => cd_input,
		output => cd_output);
  end generate;


  --==================================================
  -- Выход
  oreg_prc: process(clk)
  begin
	if(rising_edge(clk))then
		if(i_stb = '1' and i_addr /= c_zeros)then
			ostb <= '1';
		else
			ostb <= '0';
		end if;
		ostb_r <= ostb;
		ohigh  <= i_high_r(to_integer(unsigned(cd_output))); -- !!!
		oaddr  <= cd_output;
	end if;
  end process;
  
  o_stb  <= ostb_r;
  o_high <= ohigh;
  o_addr <= oaddr;
  
  
end syn;
