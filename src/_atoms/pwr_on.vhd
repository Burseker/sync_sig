--=============================
-- Developed by KST. Ver. 1.4. 
--=============================
----------------------------------------------------------------------------------
-- Company:         ������-�����
-- Engineer:        ��������� ��������
--                  
-- Create Date:     14:28 22.02.2012 
-- Design Name:     
-- Module Name:     pwr_on - behavioral
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     ���� ������������ ��������� ��� ��������� �������
--                  
--                  
-- Dependencies:    -
--                  
-- Revision:        
-- Revision 1.0 -   File Created
-- Revision 1.1 -   �������� MRK_DUR ������������ � MRK_PERIOD
--                  ������� ���� clkl ������������ � lock.
--                  ����� ����������������� ����������� ��� �������� 
--                  ������� ��������� (pon).
-- Revision 1.2 -   ��������� �������� ��� �������� ������ 
--                  (����� ��������� ���������)
-- Revision 1.3 -   ��������� ��������� PON_DEL_SIM, POR_DUR_SIM, 
--                  MRK_PERIOD_SIM, ������������ �������������� ���������
--                  ������� ��� ���������. ����� �������� �� ���������, 
--                  ������� �� ����������� � �������������.
-- Revision 1.4 -   <KST: 06.11.2012 10:16> ������� pwron_cnt ������� ������
--                  ���� ��� - � ����� ������. ����� ����������� ������� pon
--                  ���� ������������.
--                  
-- Additional Comments: 
-- 1. ��� ����������� ��������� ������� �� ������� ������� ������� ���� (lock)
-- ������������� PON_DEL ������ � ��������� ������ pon, ���������������� 
-- ��������� ����������.
-- 2. ������������ � ���������� ������� pon ��������� ������ ������ �� 
-- ��������� por, ������� ������������ � �������� ��������� POR_DUR ������.
-- 3. ������������ � ���������� ������� pon ������� ������������� ���������
-- �������� mrk, ��������� � �������� MRK_PERIOD. ��� �������� ��������
-- ����������� ����������������� ����.
-- 
-- ��� SIM = 1 ������������ ��������� PON_DEL_SIM, POR_DUR_SIM �
-- MRK_PERIOD_SIM. �������� SIM ������������ ��� ��������� ������� ���
-- ���������.
-- 
----------------------------------------------------------------------------------
--	<�����> : entity work.pwr_on
--	generic map(SIM     => , --������� ���������
--              PON_DEL => ,--�������� ������� ��������� � ������
--              POR_DUR => ,--������������ ������� ������ � ������
--              MRK_PERIOD => )--������ ���������� ����� ����������������� � ������
--  port map(   clk     => ,--�������� ������
--              lock    => ,--������� ������� ����
--              pon     => ,--������ ��������� (��������������� ���� ���
--              por     => ,--������ ������ �� ���������
--              mrk     => );--����� �����������������
----------------------------------------------------------------------------------
    
library ieee, work;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity pwr_on is
	generic(SIM            : integer range 0 to 1; --������� ���������
            PON_DEL        : integer;--�������� ������� ��������� � ������
            POR_DUR        : integer;--������������ ������� ������ � ������
            MRK_PERIOD     : integer;--������ ���������� ����� ����������������� � ������
            PON_DEL_SIM    : integer := 5;--PON_DEL ��� ���������
            POR_DUR_SIM    : integer := 4;--POR_DUR ��� ���������
            MRK_PERIOD_SIM : integer := 30--MRK_PERIOD ��� ���������
            );
	port(
        clk  : in  std_logic;--�������� ������
        lock : in  std_logic := '1';--������� ������� ����
        pon  : out std_logic;
        por  : out std_logic;
        mrk  : out std_logic
        );
end pwr_on;

architecture behavioral of pwr_on is
    --�������
	--���� SIM=0 ���������� VAL0, ����� VAL1
	function simmxi(sim,val0,val1: integer) return integer is
	begin
		if (sim = 0) then
			return(val0);
		else
			return(val1);
		end if;
	end simmxi;-----------------------------------------------
    --POWER ON
    constant pwron_cnt_lim  : integer := simmxi(SIM,PON_DEL,PON_DEL_SIM);
    signal pwron_cnt        : integer range 0 to pwron_cnt_lim-1 := 0;
    signal pwron            : STD_LOGIC := '0';
    signal pwron_rg         : STD_LOGIC := '0';
    --RESET
    constant rst_cnt_lim    : integer := simmxi(SIM,POR_DUR+1,POR_DUR_SIM+1);
    signal rst_cnt          : integer range 0 to rst_cnt_lim-1 := 0; 
	signal rst              : STD_LOGIC := '0'; --������ ������
    signal rst_rg           : STD_LOGIC := '0';
    --MARK
    constant mark_cnt_lim    : integer := simmxi(SIM,MRK_PERIOD,MRK_PERIOD_SIM);
    signal mark_cnt          : integer range 0 to mark_cnt_lim-1 := 0;
    signal mark              : STD_LOGIC := '0';
    signal mark_rg           : STD_LOGIC := '0';
begin
	
	--=============================================
	-- POWER ON
	--=============================================
    po: process(clk)
    begin
        if(rising_edge(clk))then
            if(lock = '1' and pwron = '0')then
                if(pwron_cnt = pwron_cnt_lim-1)then 
                    --pwron_cnt  <= 0;--<KST: 06.11.2012 10:16>�� � ����
                    pwron      <= '1';
                else
                    pwron      <= '0';--<KST: 06.11.2012 10:16>--�������� ������� �� Xilinx
                    pwron_cnt  <= pwron_cnt + 1;
                end if;
            end if;
        end if;
    end process;
    
    
	--=============================================
	-- POWER ON RESET
	--=============================================
    pr: process(clk)
    begin
        if(rising_edge(clk))then
            if(pwron = '1')then
                if(rst_cnt = rst_cnt_lim-1)then 
                    rst      <= '0';
                else
                    rst_cnt  <= rst_cnt + 1;
                    rst      <= '1';
                end if;
            end if;
        end if;
    end process;
	
    
	--=============================================
	-- �����
	--=============================================
    mr: process(clk)
    begin
        if(rising_edge(clk))then
            if(pwron = '1')then
                if(mark_cnt = mark_cnt_lim-1)then 
                    mark_cnt <= 0;
                    mark     <= '1';
                else
                    mark_cnt <= mark_cnt + 1;
                    mark     <= '0';
                end if;
            end if;
        end if;
    end process;
	
    
	--=============================================
	-- �������� ��������
	--=============================================
    org: process(clk)
    begin
        if(rising_edge(clk))then
            pwron_rg <= pwron;
            rst_rg   <= rst;
            mark_rg  <= mark;
        end if;
    end process;
    
    
	--=============================================
	-- �������� �����
	--=============================================
    pon <= pwron_rg;
    por <= rst_rg;
    mrk <= mark_rg;
    
end behavioral;
