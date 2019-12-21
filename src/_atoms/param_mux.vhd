--=============================
-- Developed by KST. Ver. 2.1.
--=============================
--*****************************************************************************
--Author: Stanislav Kuznetsov, Ryabkov Andrey
--Vendor: 
--Version: 
--Application: 
--Filename: param_mux.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II
--Design Name: �������
--Purpose:	param_mux - ��������������� �������������
--		���� ������������ ������ ��������������� 2:1
--
--Dependencies: 
--	* ��� ���������� ���� input ������ ����� � ������� 0 ������ ��������
--	  ������� (����� ������) �����. ��������� ����� ��������� ���� input
--	  ��������������� �� �������
--
--Reference:
--	* �� ������ ����� par_add_sub.vhd - ������ ���������/�����������
--
--Revision History:
--	Revision 0.1.0 (27/07/2011) - ������ ������
--		* �������� ������ ��������������� 4:1 ����� ����� ����������
--		  ������������ ������� ����
--	Revision 0.2.0 (19/08/2011) - ������ ������
--		* ��������� ���������, ����� ��������� ������������� ����
--		* �������� daq_mux �������� �� param_mux
--	Revision 0.2.1 (13/01/2012) - ���������� ������
--		* ��������� �������� reg_prc �������� �� �����
--
--
--*****************************************************************************

--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package pkg_param_mux is
	type t_int_array is array (integer range <>) of integer;
	function bus_nums  (ibnum: integer) return t_int_array;
	function bus_idxs  (ibnum: integer) return t_int_array;
	function log2_ceil (a: integer) return integer;
	function div_ceil  (a: integer; b : integer) return integer;
end pkg_param_mux;
--=============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_param_mux.all;

entity param_mux is
  generic (
	INUM   : integer := 4; -- ����� ������� ������
	IWIDTH : integer := 64 -- ����������� ������ �������� �����
  );
  port (
	clk    : in  std_logic;
	addr   : in  std_logic_vector(log2_ceil(INUM)-1 downto 0);
	input  : in  std_logic_vector(INUM*IWIDTH-1 downto 0);
	output : out std_logic_vector(IWIDTH-1 downto 0)
  );
end param_mux;

architecture syn of param_mux is

  --���������
  --����� ������� ��������������� 2:1
  constant c_levels_num : integer := log2_ceil(INUM);
  --����� ��� � ������ ������
  constant BUSES_NUMS   : t_int_array := bus_nums(INUM);
  --������� ������ ���� � ������ ������
  constant BUSES_IDXS   : t_int_array := bus_idxs(INUM);
  --������ �������� ����
  constant c_last_idx   : integer := BUSES_IDXS(c_levels_num);
  --����� ����� ���
  constant c_buses_num  : integer := BUSES_IDXS(c_levels_num)+1;

  --����
  type t_buses is array (integer range <>) of std_logic_vector(IWIDTH-1 downto 0);

  --�������
  signal bdat : t_buses (0 to c_buses_num-1) := (others => (others => '0'));
  
begin
  
  --=============================================
  -- ������� ����
  --=============================================
  mux_level_0: for i in 0 to BUSES_NUMS(0)-1 generate
	bdat(i) <= input((i+1)*IWIDTH-1 downto i*IWIDTH);
  end generate;
  
  
  --=============================================
  -- ������ ��������������� 2:1
  --=============================================	
  mux_levels: for j in 1 to c_levels_num generate
	--����� ��������������� � ������� ������
	constant c_mux_num : integer := BUSES_NUMS(j-1)/2;
  begin
	mux_gen: for i in 0 to c_mux_num-1 generate
		constant A_IDX : integer := BUSES_IDXS(j-1)+2*i;
		constant B_IDX : integer := BUSES_IDXS(j-1)+2*i+1;
		constant C_IDX : integer := BUSES_IDXS(j)+i;
	begin
		-- ������������� 2:1
		u_mux2_1: process(clk)
		begin
			if(rising_edge(clk))then
				if(addr(j-1) = '0')then
					bdat(C_IDX) <= bdat(A_IDX);
				else
					bdat(C_IDX) <= bdat(B_IDX);
				end if;
			end if;
		end process;
	end generate;
	
	--�������, � ������ ���� ����� �������� ���
	--����������� ������ �� ������ ������
	u_reg: if (c_mux_num*2 < BUSES_NUMS(j-1)) generate
		constant RGI_IDX : integer := BUSES_IDXS(j)-1;
		constant RGO_IDX : integer := BUSES_IDXS(j)+BUSES_NUMS(j)-1;
	begin
		reg_prc: process(clk)
		begin
			if(rising_edge(clk))then
				bdat(RGO_IDX) <= bdat(RGI_IDX);
			end if;
		end process;
	end generate;
	
  end generate;


  --=============================================
  -- �������� ����
  --=============================================
  output <= bdat(c_last_idx);
  
  
end syn;


--==============================================================================
-- ���� PACKAGE - ����������� �������
--==============================================================================
package body pkg_param_mux is
	
	--BUS_NUMS----------------------------------------------
	function bus_nums(ibnum: integer) return t_int_array is
		constant lev_num : integer := log2_ceil(ibnum);
		variable bnums : t_int_array(0 to lev_num);
	begin
		bnums(0) := ibnum;
		for i in 1 to lev_num loop
			bnums(i) := div_ceil(bnums(i-1),2);
		end loop;
		return(bnums);
	end bus_nums;-------------------------------------------

	--BUS_IDXS------------------------------------------
	function bus_idxs(ibnum: integer) return t_int_array is
		constant lev_num : integer := log2_ceil(ibnum);
		variable bnums : t_int_array(0 to lev_num);
		variable bidxs : t_int_array(0 to lev_num);
	begin
		bnums(0) := ibnum;
		bidxs(0) := 0;
		for i in 1 to lev_num loop
			bnums(i) := div_ceil(bnums(i-1),2);
			bidxs(i) := bidxs(i-1)+bnums(i-1);
		end loop;
		return(bidxs);
	end bus_idxs;---------------------------------------
	
	function log2_ceil(a : in integer) return integer is
		variable temp : integer;
	begin
		temp := 0;
		for i in 0 to 30 loop
			if (a > (2**i)) then
				temp := i+1;
			end if;
		end loop;
		return(temp);
	end log2_ceil;
	
	function div_ceil(a: integer; b : integer) return integer is
		variable temp   : integer;
	begin
		temp := a/b;
		if (temp*b < a) then
			temp := temp+1;
		end if;
		return(temp);
	end div_ceil;

end pkg_param_mux;
