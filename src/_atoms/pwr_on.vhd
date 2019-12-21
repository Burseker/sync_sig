--=============================
-- Developed by KST. Ver. 1.4. 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Станислав Кузнецов
--                  
-- Create Date:     14:28 22.02.2012 
-- Design Name:     
-- Module Name:     pwr_on - behavioral
-- Project Name:    
-- Target Devices:  
-- Tool versions:   Notepad++
-- Description:     Блок формирования признаков при включении питания
--                  
--                  
-- Dependencies:    -
--                  
-- Revision:        
-- Revision 1.0 -   File Created
-- Revision 1.1 -   Параметр MRK_DUR переименован в MRK_PERIOD
--                  Входной порт clkl переименован в lock.
--                  Метки работоспособности формируются при активном 
--                  сигнале включения (pon).
-- Revision 1.2 -   Добавлены регистры для выходных портов 
--                  (ввиду нарушения таймингов)
-- Revision 1.3 -   Добавлены параметры PON_DEL_SIM, POR_DUR_SIM, 
--                  MRK_PERIOD_SIM, определяющие соответсвующие интервалы
--                  времени при симуляции. Имеют значения по умолчанию, 
--                  поэтому не обязательны к использованию.
-- Revision 1.4 -   <KST: 06.11.2012 10:16> Счетчик pwron_cnt считает только
--                  один раз - в самом начале. После выставления сигнала pon
--                  счет прекращается.
--                  
-- Additional Comments: 
-- 1. При поступлении тактового сигнала по приходу сигнала захвата ФАПЧ (lock)
-- отсчитывается PON_DEL тактов и взводится сигнал pon, характеризуюущий 
-- включение устройства.
-- 2. Одновременно с взведением сигнала pon взводится сигнал сброса по 
-- включению por, который удерживается в активном состоянии POR_DUR тактов.
-- 3. Одновременно с взведением сигнала pon нчинают формироваться одиночные
-- импульсы mrk, следующие с периодом MRK_PERIOD. Эти импульсы являются
-- индикатором работоспособности ПЛИС.
-- 
-- При SIM = 1 используются параметры PON_DEL_SIM, POR_DUR_SIM и
-- MRK_PERIOD_SIM. Параметр SIM предназначен для повышения удбства при
-- симуляции.
-- 
----------------------------------------------------------------------------------
--	<метка> : entity work.pwr_on
--	generic map(SIM     => , --Признак симуляции
--              PON_DEL => ,--Задержка сигнала включения в тактах
--              POR_DUR => ,--Длительность сигнала сброса в тактах
--              MRK_PERIOD => )--Период следования меток работоспособности в тактах
--  port map(   clk     => ,--Тактовый сигнал
--              lock    => ,--Признак захвата ФАПЧ
--              pon     => ,--Сигнал включения (устанавливается один раз
--              por     => ,--Сигнал сброса по включению
--              mrk     => );--Метки работоспособности
----------------------------------------------------------------------------------
    
library ieee, work;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity pwr_on is
	generic(SIM            : integer range 0 to 1; --Признак симуляции
            PON_DEL        : integer;--Задержка сигнала включения в тактах
            POR_DUR        : integer;--Длительность сигнала сброса в тактах
            MRK_PERIOD     : integer;--Период следования меток работоспособности в тактах
            PON_DEL_SIM    : integer := 5;--PON_DEL при симуляции
            POR_DUR_SIM    : integer := 4;--POR_DUR при симуляции
            MRK_PERIOD_SIM : integer := 30--MRK_PERIOD при симуляции
            );
	port(
        clk  : in  std_logic;--Тактовый сигнал
        lock : in  std_logic := '1';--Признак захвата ФАПЧ
        pon  : out std_logic;
        por  : out std_logic;
        mrk  : out std_logic
        );
end pwr_on;

architecture behavioral of pwr_on is
    --ФУНКЦИИ
	--ЕСЛИ SIM=0 возвращает VAL0, иначе VAL1
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
	signal rst              : STD_LOGIC := '0'; --Сигнал сброса
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
                    --pwron_cnt  <= 0;--<KST: 06.11.2012 10:16>Ни к чему
                    pwron      <= '1';
                else
                    pwron      <= '0';--<KST: 06.11.2012 10:16>--Избегаем варнинг от Xilinx
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
	-- МЕТКА
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
	-- ВЫХОДНЫЕ РЕГИСТРЫ
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
	-- ВЫХОДНЫЕ ПОРТЫ
	--=============================================
    pon <= pwron_rg;
    por <= rst_rg;
    mrk <= mark_rg;
    
end behavioral;
