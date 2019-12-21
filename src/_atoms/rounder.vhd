--==============================================================================
-- Description: Блок усечения разрядности с округлением
-- Version:     6.0
-- Designer:    AIB
-- Workgroup:   IRS
--==============================================================================
-- Keywords:    
-- Tools:       Altera Quartus 9.1 SP1
--              
-- Note:
-- Данный блок выполняет математическое округление беззнаковых/знаковых чисел.
-- Примеры:  0.6 =>  1,  0.5 => 1,  0.49 => 0
--          -0.6 => -1, -0.5 => 0, -0.49 => 0
-- При этом необходимо учитывается возможное переполнение разрядной сетки при
-- округлении. Пример. Имеется 8ми битное знаковое число, которое необходимо 
-- урезать до 5 бит. Максимальное положительное число, описываемое 8ю битами, -
-- 127. 127/8 (сдвиг вправо на три разряда) = 15,875. По правилам это число 
-- необходимо округлить до 16, но 16 - это 1,0000 (5 бит), где запятая указывает
-- знаковый разряд. Поэтому результат сдвига 127 вправо на три разряда даст 15
-- Параметры SIGN=0(беззнаковые числа) и SMMTRC=1 (симметричный код)
-- являются взаимоисключающимися, когда SIGN=0 неважно какое значение 
-- симметричным имеет параметр SMMTRC. SMMTRC активирует функциональность работы
-- с кодом в пределах (out={-127, 127})
-- 
-- Version History:
-- Ver 1.0 -   [AIB][дата] Рабочая версия с зависимостью от файла truncator.vhd
-- Ver 2.0 -   [AIB][дата] Устранена зависимость от файла truncator.vhd
--             Блок стал полностью независимым
-- Ver 3.0 -   [AIB][дата] Из текста блока truncator удалена лишняя 
--             фукнциональность. Исправлен алгоритм округления.
--             Добавлена функциональность округления беззнаковых чисел
-- Ver 4.0 -   [AIB][03.12.13] Выкинут сигнал s_limitval --ЗНАЧЕНИЕ ОГРАНИЧЕНИЯ,
--             данная операция заменена на инверсию s_sum_out(OWIDTH downto 1);
--             также выкинут сигнал s_signbit за ненадобностью
-- Ver 5.0 -   [AIB][6.12.13] Добавлена функциональность. Можно выбрать операции
--             с симметричным (out={-127, 127})и несимметричным кодом
--             (-128, 127)
-- Ver 6.0     [KST][20.12.13] Добавлена фукнциональность. Появилась возможность
--              производить усечение старших разрядов для экономии ресурсов ПЛИС      
-- Ver 6.1     [AIB][10.06.14] Special for ModelSim поправлен выбор той или иной
--              реализации в зависимости от входной разрядности: то ли имеет место
--              ограничитель, который исключает минимальное отрицательное число,
--              то ли блок, который выполняет остальные функции rounder.
--              На заметку: конструкция when-else воспринимается ModelSim как
--              мультиплексор, который надлежит реализовывать в любом случае.      
--------------------------------------------------------------------------------

    -- <loop>: entity work.rounder
    -- generic map (
    --      IWIDTH  => , -- входная разрдяность
    --      OWIDTH  => , -- выходная разрядность
    --      MSBTN   => , -- Число отбрасываемых старших бит
    --      SIGN    => , -- true - знаковые, false - беззнаковые
    --      SMMTRC  => , -- true - симметричный код, false - несимметричный
    --      SUM_RG  => , -- регистр после сумматора: true - есть, false - нет
    --      OUT_RG  =>   -- выходной регистр: true - есть, false - нет
    -- )
    -- port map (
    --      aclr    => aclr,
    --      clk     => clk,
    --      en      => en,
    --      di      => ,
    --      do      =>     
    -- );
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rounder is
	generic(
		IWIDTH		: natural ; -- входная разрдяность
		OWIDTH		: natural ; -- выходная разрядность
        MSBTN       : natural ; -- Число отбрасываемых старших бит
        SIGN        : boolean ; -- true - знаковые, false - беззнаковые
        SMMTRC      : boolean ; -- true - симметричный код, false - несимметричный
        SUM_RG      : boolean ; -- регистр после сумматора: true - есть, false - нет
        OUT_RG		: boolean   -- выходной регистр: true - есть, false - нет
	);
	port (
		aclr		: in std_logic;
		clk			: in std_logic;
		en			: in std_logic;
		di			: in std_logic_vector  (IWIDTH-1 downto 0);
		do			: out std_logic_vector (OWIDTH-1 downto 0)
	);
end rounder;
	
architecture beh of rounder is
    -- type bool is array (boolean) of std_logic;
    -- constant  B2SL  : bool := ('0','1');
    
    -- Функция преобразования boolean в std_logic
    function B2SL (b : boolean) return std_logic is begin
        if(b)then return '1'; else return '0'; end if; end;
    
    -- Признак включения округляющего сумматора
    constant C_SUM_ON       	: boolean := IWIDTH > (OWIDTH + MSBTN);
    -- Разрядность округляющего сумматора
    constant C_SUM_WIDTH        : natural := MSBTN+OWIDTH+2;
    -- Минимальное отрицательное число для симметризации
    constant C_MIN_NEGATIVE_VAL : std_logic_vector (OWIDTH downto 1)
                                := '1' & (OWIDTH-1 downto 1 => '0');
                                
    -- Округляющий сумматор
    signal s_sum_in             : std_logic_vector (C_SUM_WIDTH-1 downto 0);
    signal s_sum                : std_logic_vector (C_SUM_WIDTH-1 downto 0);
    signal s_sum_out            : std_logic_vector (C_SUM_WIDTH-1 downto 0) 
                                := (others => '0');
    -- Симметриализатор
    signal s_smmtrc             : std_logic;
    -- Усекатель разрядности
    signal s_etalon             : std_logic_vector(MSBTN+1-1 downto 0);
    signal s_ovfflag            : std_logic;
    signal s_ovf_result         : std_logic_vector(OWIDTH-1 downto 0);
    signal s_truncator          : std_logic_vector(OWIDTH-1 downto 0);
    -- Результат
    signal s_do                 : std_logic_vector(OWIDTH-1 downto 0) 
                                := (others => '0');
begin
    --==================================================
    -- ОТСЛЕЖИВАНИЕ ОШИБОК
    --==================================================
    assert (IWIDTH >= OWIDTH+MSBTN)
    report "Wrong parameters! Must be: IWIDTH >= OWIDTH + MSBTN!"
    severity ERROR;
    
    --==================================================
    -- ОКРУГЛЯЮЩИЙ СУММАТОР
    --==================================================   

    --СУММАТОР ВКЛЮЧЕН
    sum_on: if(C_SUM_ON) generate
    begin
        s_sum_in <= ((di(IWIDTH-1) and B2SL(SIGN)) &      --Расширение знака
                di(IWIDTH-1 downto IWIDTH-MSBTN-OWIDTH-1));
        s_sum    <= std_logic_vector(signed(s_sum_in) + 1) when SIGN
                    else std_logic_vector(unsigned(s_sum_in) + 1);
    end generate;
    --СУММАТОР ВЫКЛЮЧЕН
    sum_off: if(not C_SUM_ON) generate
        s_sum_in <= ((di(IWIDTH-1) and B2SL(SIGN)) & --Расширение знака
                di(IWIDTH-1 downto IWIDTH-MSBTN-OWIDTH) & '0');
        s_sum    <= s_sum_in;
    end generate;

    --==================================================
    -- РЕГИСТР ОКРУГЛЯЮЩЕГО СУММАТОРА
    --==================================================
	--ЕСЛИ НЕТ РЕГИСТРА
    sum_rg_off: if(not SUM_RG)generate
	begin
		s_sum_out <= s_sum;
	end generate;
    --ЕСЛИ ЕСТЬ РЕГИСТР
    sum_rg_on:if(SUM_RG)generate
	begin
		prc: process (aclr, clk)
		begin
			if(aclr = '1')then
				s_sum_out <= (others => '0');
			elsif(rising_edge(clk))then
                if(en ='1')then
					s_sum_out <= s_sum;
				end if;
			end if;
		end process;
	end generate;
	
    --==================================================
    -- КОМПАРАТОР ДЛЯ СИММЕТРИАЛИЗАЦИИ
    --==================================================
    s_smmtrc    <= '1' when (s_sum_out(OWIDTH downto 1) = C_MIN_NEGATIVE_VAL) and 
                         (SMMTRC and SIGN)
                else '0' ;
    
    --==================================================
    -- УСЕЧЕНИЕ РАЗРЯДНОСТИ С ОГРАНИЧЕНИЕМ
    --==================================================
    --ПОДГОТОВКА ИСХОДНЫХ ДАННЫХ
    s_etalon    <= (others => s_sum_out(C_SUM_WIDTH-(MSBTN+1)-1)) when SIGN 
                   else (others => '0');
    --ФОРМИРОВАНИЕ ПРИЗНАКА ПЕРЕПОЛНЕНИЯ
    s_ovfflag   <= '0' when (s_sum_out(C_SUM_WIDTH-1 downto C_SUM_WIDTH-(MSBTN+1)) = s_etalon) 
                   else '1';
    --РЕЗУЛЬТАТ ДЛЯ СЛУЧАЯ ПЕРЕПОЛНЕНИЯ
    -- s_ovf_result<= (s_sum_out(C_SUM_WIDTH-1) or not B2SL(SIGN)) & -- Учет знака
                   -- (OWIDTH-1-1 downto 1 => not s_sum_out(C_SUM_WIDTH-1)) & 
                   -- -- Учет симметриализации
                   -- (not s_sum_out(C_SUM_WIDTH-1) or B2SL(SMMTRC));
    s_ovf_result<= s_sum_out(C_SUM_WIDTH-1) & 
                   (OWIDTH-1-1 downto 1 => not s_sum_out(C_SUM_WIDTH-1)) & 
                   -- Учет симметриализации
                   (not s_sum_out(C_SUM_WIDTH-1) or B2SL(SMMTRC))
                   when SIGN else (others => '1');
    --МУЛЬТИПЛЕКСОР
    s_truncator <=  s_ovf_result when (s_ovfflag = '1')
                    else s_sum_out(OWIDTH downto 2)&(s_sum_out(1) or s_smmtrc);
    
    --==================================================
    --ВЫХОДНОЙ РЕГИСТР
    --==================================================
    --ЕСЛИ НЕТ РЕГИСТРА
    org_off: if(not OUT_RG)generate
        s_do <= s_truncator;
    end generate;
    --ЕСЛИ ЕСТЬ РЕГИСТР
    org_on: if(OUT_RG)generate
        process(aclr,clk)
        begin
            if(aclr = '1')then
                s_do <= (others => '0');
            elsif rising_edge(clk) then
                if(en = '1')then
                    s_do <= s_truncator;
                end if;
            end if;
        end process;
    end generate;
    
    --==================================================
    --ВЫХОДНОЙ ПОРТ
    --==================================================
    do <= s_do;
    
    
end beh;
