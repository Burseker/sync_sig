--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: addr_dc.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: �������
--Purpose:	addr_dc - ���������� ������ flex_packer
--
--Dependencies:
--		* ��������� OWIDTH = 32
--
--Reference:
--
--Revision History:
--	Revision 0.1.0 (22/09/2011) - ������ ������
--		* �������� ����� �� ����� o_stb
--	Revision 0.1.1 (26/09/2011) - ����� ��������� ��������
--		+ � ������ i_addr �������� ������� ������, �������
--		  ��������� dmux1_2_r - ����� ������ ��
--		  ���� �������� ���������
--		+ ���� o_high
--	Revision 0.1.2 (27/09/2011) - �������� ����� �� �����
--		- ������ �������� ����� o_stb
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_packer1x.all;

entity addr_dc is
  generic (
	OWIDTH : integer := 32
  );
  port (
	clk    : in  std_logic;
	
	i_stb  : in  std_logic;
	i_ena  : in  std_logic; -- ���������� ������ �����
	i_addr : in  std_logic_vector(log2_ceil(OWIDTH) downto 0); -- log2_ceil(32) = 5
	
	o_high : out std_logic;
	o_addr : out std_logic_vector(OWIDTH-1 downto 0)
  );
end addr_dc;

architecture syn of addr_dc is

  signal dc_input  : std_logic_vector(log2_ceil(OWIDTH)-1 downto 0) := (others=>'0');
  signal dc_output : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal oaddr     : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal ohigh     : std_logic := '0';

begin

  --==================================================
  -- ����������
  dc_input <= i_addr(i_addr'length-2 downto 0);

  ow_32_gen: if (OWIDTH = 32) generate
	u_dc5x32: dc_5x32_r
	GENERIC MAP(
		OREG => false)
	PORT MAP(
		clk    => clk,
		input  => dc_input,
		output => dc_output);
  end generate;
  

  --==================================================
  -- �����
  oreg_prc: process(clk)
  begin
	if(rising_edge(clk))then
		if(i_stb = '1' and i_ena = '1')then
			-- ostb  <= '1';
			oaddr <= dc_output;
		else
			-- ostb  <= '0';
			oaddr <= (others=>'0');
		end if;
		ohigh <= i_addr(i_addr'length-1);
	end if;
  end process;
  
  o_high <= ohigh;
  o_addr <= oaddr;
  
  
end syn;
