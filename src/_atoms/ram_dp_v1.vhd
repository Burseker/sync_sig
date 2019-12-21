--=============================
-- Developed by SVB. Ver. 1.3.0 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Сергей Бураков 
--                  
-- Create Date:     15:05 25.03.2012 
-- Design Name:     
-- Module Name:     ram_dp_v1 - behavioral
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     Блок двухпортовой памяти
--                  
--                  
-- Dependencies:    нет
--                  
-- Revision:        
-- Revision 1.0.0 - Двухпортовая память(независимые адреса чтения и записи).
--					Рабочая версия.
-- Revision 1.1.0 - Исправлена ошибка инициализации памяти в зависимотсти от STYLE
-- Revision 1.2.0 - Добавлена опция дополнительного выходного регистра OREG
-- Revision 1.3.0 - Добавлена возможность инициализации элементов памяти массивом 
--					INIT_ARR, разрядность элемента  meminit_t указана в ram_dp_func_pkg
--					для инициализации берется младшая часть
-- 
-- 
-- 
--                  
-- Additional Comments: 
-- 
-- 
-- 
-- 
-- 
-- 
----------------------------------------------------------------------------------
--PACKAGE
library ieee,work;
use ieee.std_logic_1164.all;
package ram_dp_func_pkg is
	function log2ceil(a : in integer) return integer;
	
	constant C_MAXINIT_WIDTH : natural := 64;
	--subtype word_t is std_logic_vector(natural range <>);
	type meminit_t is array(natural range <>) of std_logic_vector(C_MAXINIT_WIDTH-1 downto 0);
	
end ram_dp_func_pkg;
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Revision 1.2.0
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--	<метка> : entity work.ram_dp_v1
--	generic map(
--		WIDTH  => ,
--		DEPTH  => ,
--      STYLE  => ,
--		OREG => 0)
--	port map(
--		clk    => ,
--
--		idata  => ,
--		w_addr => ,
--		wr     => ,
--		
--		r_addr => ,
--		odata  => 
--	);
----------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.all;  
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_unsigned.all;
use work.ram_dp_func_pkg.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity ram_dp_v1 is
    generic	(
        WIDTH 	: integer;--Разрядность слова данных
        DEPTH 	: integer;--Объем памяти в словах
        STYLE 	: string := "Auto"; --Тип памяти:
                        --Altera: "Auto", "M512", "M4K", "M-RAM", "MLAB", "M9K", "M144K", "logic"
                        --Xilinx: "Auto"
		OREG	: integer := 0;
		
		INIT_ARR: meminit_t := (conv_std_logic_vector(0, C_MAXINIT_WIDTH),
									conv_std_logic_vector(0, C_MAXINIT_WIDTH))
        );
    port(
		clk   	: in  std_logic;
		
		idata 	: in  std_logic_vector(WIDTH-1 downto 0);
		w_addr	: in  std_logic_vector(log2ceil(DEPTH)-1 downto 0);
		wr    	: in  std_logic;     
		
		odata 	: out std_logic_vector(WIDTH-1 downto 0);
		r_addr	: in  std_logic_vector(log2ceil(DEPTH)-1 downto 0)
    );
end ram_dp_v1;

architecture behav of ram_dp_v1 is
	
	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector((WIDTH-1) downto 0);
	type memory_t is array(DEPTH-1 downto 0) of word_t;
	
	signal s_odata : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
	signal rg_out : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
	
	impure function init_mem return memory_t is
		variable temp_mem : memory_t;
		variable V_INIT_WIDTH : natural;
	begin
        if(C_MAXINIT_WIDTH < WIDTH) then V_INIT_WIDTH := C_MAXINIT_WIDTH;
        else V_INIT_WIDTH := WIDTH; end if;
        
		for i in memory_t'range loop
			if i <= INIT_ARR'high then
				temp_mem(i)(V_INIT_WIDTH-2 downto 0) := INIT_ARR(i)(V_INIT_WIDTH-2 downto 0);
				temp_mem(i)(WIDTH-1 downto V_INIT_WIDTH-1) := (others => INIT_ARR(i)(V_INIT_WIDTH-1));
			else
				temp_mem(i) := (others => '0');
			end if;
		end loop;
		return temp_mem;
	end function;
	
begin

	style_gen1: if ( STYLE = "Auto" or STYLE = "M512" or STYLE = "M4K" or STYLE = "logic" ) generate
	-- Declare the RAM 
	signal ram : memory_t := init_mem;
		
	attribute ramstyle : string; 
    attribute ramstyle of ram : signal is STYLE;
	
	begin
		--========================================
		--ПАМЯТЬ
		--========================================
		ram_inst: process (clk)
		begin
			if(rising_edge(clk))then
				if(wr = '1')then
					ram(CONV_INTEGER(w_addr)) <= idata;
				end if;
				rg_out <= ram(CONV_INTEGER(r_addr));
			end if;
		end process;
	end generate;
	
	style_gen2: if ( STYLE = "M-RAM" ) generate
	-- Declare the RAM 
	signal ram : memory_t;
	attribute ramstyle : string; 
    attribute ramstyle of ram : signal is STYLE;
	
	begin
		--========================================
		--ПАМЯТЬ
		--========================================
		ram_inst: process (clk)
		begin
			if(rising_edge(clk))then
				if(wr = '1')then
					ram(CONV_INTEGER(w_addr)) <= idata;
				end if;
				rg_out <= ram(CONV_INTEGER(r_addr));
			end if;
		end process;
	end generate;
	
	
	--========================================
	--Без дополнителоьного выходного регистра
	--========================================
	oreg_gen0: if ( OREG = 0 ) generate
	begin
		s_odata <= rg_out;
	end generate;
	
	
	--========================================
	--С дополнителоьным выходным регистром
	--========================================	
	oreg_gen1: if ( OREG = 1 ) generate
	signal rg_out_r1 : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
	begin
		process (clk)
		begin
			if(rising_edge(clk))then
				rg_out_r1 <= rg_out;
			end if;
		end process;
		
		s_odata <= rg_out_r1;
	end generate;
	
	
	--========================================
	--Выходной порт
	--========================================
	odata <= s_odata;
	
end behav;

----------------------------------------------------------------------------------
--PACKAGE
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package body ram_dp_func_pkg is
	function log2ceil(a : in integer) return integer is
		variable temp : integer;
	begin
		temp := 1;
		for i in 0 to 30 loop
			if (a > (2**i)) then
				temp := i+1;
			end if;
		end loop;
		return(temp);
	end log2ceil;
	
	
	
end ram_dp_func_pkg;
----------------------------------------------------------------------------------