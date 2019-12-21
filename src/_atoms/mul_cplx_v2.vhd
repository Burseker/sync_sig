--=============================
-- Developed by SVB. Ver. 1.0.0 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Сергей Бураков
--                  
-- Create Date:     14:30 12.12.2011 
-- Design Name:     
-- Module Name:     mul_cplx_v2 - beh
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     Умножитель комплексных чисел(облегечнный алгоритм) 
--                  e + j*f = (a+j*b)*(c+j*d)
--                  e = (a-b)*d + (c-d)*a
--					f = (a-b)*d + (c+d)*b             
--                  
-- Dependencies:    независимый блок
--                  
-- Revision:        
-- Revision 1.0.0 -   File Created
--                  
--                  
--                  
--                  
-- Additional Comments: Используется только 3 умножителя
-- 						Конвейерная задержка блока 3 такта clk
-- 
-- 
-- 
----------------------------------------------------------------------------------
--	<метка> : entity work.mul_cplx_v2
--	generic map(
--		IWIDTH =>
--		)
--	port map(
--		aclr  => ,
--		clk   => ,
--		sclr  => ,
--
--		istb  => ,
--		idt_a => ,
--		idt_b => ,
--		idt_c => ,
--		idt_d => ,
--
--		ostb  => ,
--		odt_e => ,
--		odt_f => ,
--	);
----------------------------------------------------------------------------------
    
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_cplx_v2 is
	generic(IWIDTH : integer := 18 --Разрядность входных операндов
		);
	port(
		aclr : in  std_logic;
		clk  : in  std_logic;
		sclr : in  std_logic;
		
		istb : in  std_logic;
		idt_a   : in  std_logic_vector (IWIDTH-1 downto 0);
        idt_b   : in  std_logic_vector (IWIDTH-1 downto 0);
		idt_c   : in  std_logic_vector (IWIDTH-1 downto 0);
        idt_d   : in  std_logic_vector (IWIDTH-1 downto 0);
		
		ostb  : out std_logic;
		odt_e   : out std_logic_vector (IWIDTH*2 downto 0);
        odt_f   : out std_logic_vector (IWIDTH*2 downto 0)
		);
end mul_cplx_v2;

architecture behavioral of mul_cplx_v2 is

	--функция расширяет знаковый разряд, увеличивая разрядность числа на Cnt
	function bit_wider(Arg : signed; Cnt : natural) return signed is

		variable tmp : signed(Arg'high + Cnt downto 0);
		constant lo  : integer := Arg'high + Cnt;

	begin

		for n in lo downto Arg'high+1 loop
			tmp(n) := Arg(Arg'high);
		end loop;
		
		for n in Arg'high downto 0 loop
			tmp(n) := Arg(n);
		end loop;

		return tmp;
		
	end function bit_wider;
	
	constant PRE_CALK_WIDTH: natural := IWIDTH + 1;
	constant MUL_WIDTH: natural := IWIDTH + PRE_CALK_WIDTH;
	constant OUT_WIDTH: natural := MUL_WIDTH;

	signal istb_r1, istb_r2, istb_r3: std_logic := '0';
	
	signal s_dt_amb	:   signed(PRE_CALK_WIDTH-1 downto 0) := (others => '0');
	signal s_dt_cmd	:   signed(PRE_CALK_WIDTH-1 downto 0) := (others => '0');
	signal s_dt_cpd	:   signed(PRE_CALK_WIDTH-1 downto 0) := (others => '0');
	
	signal idt_a_r1	:   signed(IWIDTH-1 downto 0) := (others => '0');
	signal idt_b_r1	:   signed(IWIDTH-1 downto 0) := (others => '0');
	signal idt_d_r1	:   signed(IWIDTH-1 downto 0) := (others => '0');
	
	signal s_dt_abd	:	signed(MUL_WIDTH-1 downto 0) := (others => '0');
	signal s_dt_acd	:	signed(MUL_WIDTH-1 downto 0) := (others => '0');
	signal s_dt_bcd	:	signed(MUL_WIDTH-1 downto 0) := (others => '0');
	
	signal s_e		:	signed(OUT_WIDTH-1 downto 0) := (others => '0');
	signal s_f		:	signed(OUT_WIDTH-1 downto 0) := (others => '0');
	
begin

--задержка входного строба
stb_line: process(aclr, clk)
begin
	if(aclr = '1')then
		istb_r1 <= '0';
		istb_r2 <= '0';
		istb_r3 <= '0';
		
	elsif(rising_edge(clk)) then
		if(sclr = '1')then
			istb_r1 <= '0';
			istb_r2 <= '0';
			istb_r3 <= '0';
		else
			istb_r1 <= istb;
			istb_r2 <= istb_r1;
			istb_r3 <= istb_r2;
		end if;
	end if;
end process;
	
--предварительные суммы
	pre_calk: process(clk)
	begin
		if(rising_edge(clk)) then
			if(istb = '1') then
				s_dt_amb <= bit_wider(signed(idt_a), 1) - bit_wider(signed(idt_b), 1);
				s_dt_cmd <= bit_wider(signed(idt_c), 1) - bit_wider(signed(idt_d), 1);
				s_dt_cpd <= bit_wider(signed(idt_c), 1) + bit_wider(signed(idt_d), 1);
				
				idt_a_r1 <= signed(idt_a);
				idt_b_r1 <= signed(idt_b);
				idt_d_r1 <= signed(idt_d);
			end if;
		end if;
	end process;
	
--умножители
	mul_calk: process(clk)
	begin
		if(rising_edge(clk)) then
			if(istb_r1 = '1') then
				s_dt_abd <= s_dt_amb * idt_d_r1;
				s_dt_acd <= idt_a_r1 * s_dt_cmd;
				s_dt_bcd <= idt_b_r1 * s_dt_cpd;
			end if;
		end if;
	end process;
	
--выходной мультиплексор
	osum_calk: process(clk)
	begin
		if(rising_edge(clk)) then
			if(istb_r2 = '1') then
				s_e <= s_dt_abd + s_dt_acd;
				s_f <= s_dt_abd + s_dt_bcd;
			else
				s_e <= (others => '0');
				s_f <= (others => '0');
			end if;
		end if;
	end process;
	
	odt_e   <= std_logic_vector(s_e);
    odt_f   <= std_logic_vector(s_f);
	ostb  <= istb_r3;
	
end behavioral;
