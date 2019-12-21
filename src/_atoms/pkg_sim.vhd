--=============================
-- Developed by KST. Ver. 1.0.1
--=============================
--==========================================================
--��� ���������
-- Revision 1.0.0 - �������� �����
-- Revision 1.0.1 - ��������� ������� simmxslv
--==========================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package pkg_sim is

	function simmx(sim: integer;val0,val1: std_logic) return std_logic;
	function simmxslv(sim: integer;val0,val1: std_logic_vector) return std_logic_vector;
	function simmxi(sim,val0,val1: integer) return integer;

end pkg_sim;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


package body pkg_sim is

	--SIMMXI(SIM,VAL0,VAL1)---------------------------------------------
	--���� SIM=1 ���������� VAL0, ����� VAL1
	function simmxi(sim,val0,val1: integer) return integer is
	begin
		if (sim = 0) then
			return(val0);
		else
			return(val1);
		end if;
	end simmxi;-----------------------------------------------

    --SIMMXSLV(SIM,VAL0,VAL1)---------------------------------------------
	--���� SIM=1 ���������� VAL0, ����� VAL1
	function simmxslv(sim: integer;val0,val1: std_logic_vector) return std_logic_vector is
	begin
		if (sim = 0) then
			return(val0);
		else
			return(val1);
		end if;
	end simmxslv;-----------------------------------------------
    
	--SIMMX(SIM,VAL0,VAL1)---------------------------------------------
	--���� SIM=1 ���������� VAL0, ����� VAL1
	function simmx(sim: integer;val0,val1: std_logic) return std_logic is
	begin
		if (sim = 0) then
			return(val0);
		else
			return(val1);
		end if;
	end simmx;-----------------------------------------------

end pkg_sim;