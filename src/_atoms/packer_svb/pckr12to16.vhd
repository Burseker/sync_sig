--=============================
-- Developed by SVB. Ver. 0.5.0 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Сергей Бураков
--                  
-- Create Date:     27.10.2014
-- Design Name:     pckr12to16
-- Module Name:     pckr12to16 - Beh
-- Project Name:    Quartet
-- Target Devices:  Stratix II: EP2S60F484I4
-- Tool versions:   Notepad++
-- Description:     Перепаковка пакетного потока из 12и в 16
--                  разряднй код
--                  
--                  
-- Dependencies:    
--                  
-- Revision:        
-- Revision 0.0.0 - File created   
-- Revision 0.1.0 - Первая рабочая версия, сигнал ten транслируется с выходного
--                  потока на входной.
-- Revision 0.3.0 - Канал выходного мультиплексора определяется счетчиком s_path_cnt
--                  тот в свою очередь изменяется на основе счетчика битов s_bit_cnt, 
--                  флагов s_spctail и s_exitreg
-- Revision 0.4.0 - Добавлен параметр перепаковки ENDIANNESS, в алгоритм внесена 
--                  соответствующая ветка           
-- Revision 0.5.0 - Assert на проверку ENDIANNESS: ERROR сменен на FAILURE     
--                  
-- Additional Comments: 
-- 
--     
-- 
-- 
-- 
-- 
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use work.pkg_sim.all;
use work.pkg_func.all;
--=========================

entity pckr12to16 is
    generic(
        -- IWIDTH  : natural := 12;
        -- OWIDTH  : natural := 16
        ENDIANNESS : string := "BIG_ENDIAN" -- "BIG_ENDIAN", "LITTLE_ENDIAN"
    );
    port (
        aclr    : in  std_logic;
        clk     : in  std_logic;
        
        idat    : in  std_logic_vector(11 downto 0);
        istb    : in  std_logic;
        iend    : in  std_logic;
        iten    : out std_logic;
        
        odat    : out std_logic_vector(15 downto 0);
        ostb    : out std_logic;
        oend    : out std_logic;
        oten    : in  std_logic
    );
end pckr12to16;

architecture beh of pckr12to16 is

    constant C_IWIDTH   : natural := 12;
    constant C_OWIDTH   : natural := 16;
    constant C_SH_STEP  : natural := C_OWIDTH - C_IWIDTH;
    constant C_RGWORDS  : natural := 2;
    constant C_CNTWIDTH : natural := log2_ceil(C_IWIDTH*C_RGWORDS);
    
    -- линия задержки для данных входной разрядности, задержка на длину заголовка с ловах WIDTH
    type t_dl_slvarr is array (natural range 0 to C_RGWORDS-1) of std_logic_vector(C_IWIDTH-1 downto 0);
    signal s_dl_slvarr  : t_dl_slvarr := (others => (others => '0'));
    
    signal s_looprg     : std_logic_vector( C_IWIDTH*C_RGWORDS-1 downto 0 ) := (others => '0');
    
    signal s_iten       : std_logic := '0';
    signal s_astb       : std_logic := '0';
    signal s_aend       : std_logic := '0';
    --счетчик бит текущего пакета
    signal s_bit_cnt    : unsigned(5 downto 0) := (others => '0');
    --счетчик виртуального выходного адреса
    signal s_path_cnt   : unsigned(5 downto 0) := (others => '0');
    --стробы чтения из регистров и прокрутки адреса
    signal s_shstb      : std_logic := '0';
    signal s_rdstb      : std_logic := '0';
    --управление перепаковкой в конце пакета
    signal s_spctail    : std_logic := '0';
    signal s_exitreg    : std_logic_vector( C_RGWORDS-1 downto 0) := (others => '0'); 
    
    signal s_odat       : std_logic_vector( C_OWIDTH-1 downto 0) := (others => '0');
    signal s_ostr       : std_logic := '0';
    signal s_oend       : std_logic := '0';
    signal s_ostb       : std_logic := '0';
    
begin
    assert (ENDIANNESS = "BIG_ENDIAN" or ENDIANNESS = "LITTLE_ENDIAN")
    report "pckr12to16: Wrong value of parameter 'ENDIANNESS'. Read the description!" 
    severity FAILURE;
    
    
  --=============================================
-- TYPICAL PROCESS
--=============================================
    -- process(aclr, clk)
    -- begin
        -- if(aclr = '1')then
        -- elsif(rising_edge(clk))then
        -- end if;
    -- end process;
    
    
--=============================================
-- РЕГИСТРАЦИЯ СТРОБОВ СОПРОВОЖДЕНИЯ
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_astb <= '0';
            s_aend <= '0';
        elsif(rising_edge(clk))then
            s_astb <= istb;
            
            if( istb = '1' )then s_aend <= iend;
            else s_aend  <= '0'; end if;
            
        end if;
    end process;
    
    
--=============================================
-- ЛИНИЯ ЗАДЕРЖКИ ПЕРЕПАКОВЩИКА
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_dl_slvarr <= (others => (others => '0'));
        elsif(rising_edge(clk))then
            if( istb = '1' )then
                s_dl_slvarr(0) <= idat;
            end if;
            
            if( s_astb = '1' )then
                s_dl_slvarr(1) <= s_dl_slvarr(0);
            end if; 
            
        end if;
    end process;    
    
    
--=============================================
-- СЧЕТЧИК БИТОВ ВХОДНОГО ПАКЕТА
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_bit_cnt  <= (others => '0');
        elsif(rising_edge(clk))then
            
            if( s_aend = '1' )then  -- конец пакета в начале ЛЗ
                if( istb = '1' )then  -- есть данные нового пакета
                    s_bit_cnt <= to_unsigned(C_IWIDTH, s_bit_cnt'length);
                else   -- нет данных нового пакета
                    s_bit_cnt <= (others => '0');
                end if;
                
            elsif( s_shstb = '1' )then  -- в ЛЗ достаточно бит для перепаковки
                if( istb = '1' )then
                    s_bit_cnt <= s_bit_cnt - C_SH_STEP;
                else
                    s_bit_cnt <= s_bit_cnt - C_OWIDTH;
                end if;
                
            else    -- 
                if( istb = '1' )then
                    s_bit_cnt <= s_bit_cnt + C_IWIDTH;
                end if;
            end if;
        
        end if;
    end process;
    -- проверка условия достаточности бит для перпаковки
    s_shstb <= '1' when s_bit_cnt >= C_OWIDTH else '0'; 
   
   
--=============================================
--ФЛАГ КОНЦА ПАКЕТА С ПОЛНЫМ ЦИКЛОМ ПЕРЕПАКОВКИ
--=============================================
s_spctail <= '1' when ( s_bit_cnt = C_OWIDTH and s_aend = '1' ) else '0';

--=============================================
-- СТАДИЯ ОБРАБОТКИ КОНЦА ПАКЕТА
--=============================================    
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_exitreg <= ( others => '0' );
        elsif(rising_edge(clk))then
        
            if( ( istb and iend ) = '1' ) then
                s_exitreg(0) <= '1';
            else
                s_exitreg(0) <= '0';
            end if;
            
            s_exitreg(1) <= s_exitreg(0) and not s_spctail;
            
            -- b"00" - обрабатывается тело пакета
            -- b"10" - есть поледние разряды в старшей половине или конец цикла
            -- b"01" - есть поледние разряды в младшей половине
            -- b"11" - есть поледние разряды и в младшей и в старшей половине
            --          можнт быть если идут подряд 2 и более конца пакета
        end if;
    end process;
    
--=============================================
-- СЧЕТЧИК ВЫХОДНОГО МУЛЬТИПЛЕКСОРА
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_path_cnt  <= (others => '0');
        elsif(rising_edge(clk))then
            
            
            --*** Ветвь 1 ***
            if( s_spctail = '1' )then                                   -- s_exitreg = b"01" особый случай
            -- особый случай, коенц пакета формируется в след такте после
            -- строба конца пакета на входе(целый цикл перепаковки)
                if( istb = '1' )then
                    s_path_cnt <= to_unsigned(C_IWIDTH, s_path_cnt'length);
                else
                    s_path_cnt <= (others => '0');
                end if;
                
            --*** Ветвь 2 ***    
            elsif( s_exitreg(0) = '1' )then                             -- s_exitreg = b"11" or s_exitreg = b"01"
            -- формирование хвоста пакета(неоконченного)
                if( s_rdstb = '1' and s_exitreg(1) = '0' )then      
                    -- конец пакета формируется за 2 такта, т.е.
                    -- s_exitreg = b"01" (конец пакета загружен)
                    -- а также есть чтение из регистра
                    s_path_cnt <= s_bit_cnt - C_SH_STEP;
                else
                    -- следующие ситуации:
                    -- s_exitreg = b"11" безразлично к s_rdstb т.к. последнее слово пакета
                    -- s_exitreg = b"01" но нет чтения(слово пропускается во 2-ю часть регистра)
                    s_path_cnt <= s_bit_cnt + C_IWIDTH;
                end if;
            
            --*** Ветвь 3 ***            
            --elsif( s_exitreg = b"10" )then                            -- s_exitreg = b"10" здесь не учитывается s_rdstb это важно!!!!
                                                                        -- не учитывается в смысле не происходит декремента счетчика
                                                                        -- чтение происходящее в текущем такте относится к текущему пакету
                                                                        -- в следующем такте обрабатывается следующий пакет
                                                                        -- можно объединить с веткой 5 т.к. там счетчик ведет себя так же
            elsif( s_exitreg = b"10" or s_rdstb = '0' )then  
            -- формирование хвоста пакета
                if( istb = '1' )then
                    s_path_cnt <= s_bit_cnt + C_IWIDTH;
                else
                    s_path_cnt <= s_bit_cnt;
                end if;
            
            --*** Ветвь 4 ***
            -- elsif( s_rdstb = '1' )then                               -- s_exitreg = b"00" здесь s_rdstb имеет значение это важно!!!!
            else
            -- формирование тела пакета(параллельно с s_bit_cnt)
                if( istb = '1' )then
                    s_path_cnt <= s_bit_cnt - C_SH_STEP;
                else
                    s_path_cnt <= s_bit_cnt - C_OWIDTH;
                end if;
            
            --*** Ветвь 5 ***
            -- else                                                        -- s_exitreg = b"00" 
                -- -- концы пакета дорабатываются автоматически
                -- -- в данном кейсе может отрабатываться только тело пакета
                -- if( istb = '1' )then
                    -- s_path_cnt <= s_bit_cnt + C_IWIDTH;
                -- else
                    -- s_path_cnt <= s_bit_cnt;
                -- end if;
            end if;
            
        end if;
    end process;
    -- проверка условия достаточности бит для перпаковки
    s_rdstb <= '1' when s_path_cnt >= C_OWIDTH else '0'; 
    
    
--=============================================
-- ПЕРЕПАКОВКА В РЕЖИМЕ BIG_ENDIAN
--=============================================
    big_endian_gen: if(ENDIANNESS = "BIG_ENDIAN") generate
        --=============================================
        -- ПРИВЕДЕНИЕ РЕГИСТРА
        --=============================================
        rgfil_gen: for i in 0 to C_RGWORDS-1 generate
            s_looprg(C_IWIDTH*(i+1)-1 downto C_IWIDTH*i) <= s_dl_slvarr(i);
        end generate rgfil_gen;
        
        
        --=============================================
        -- ТАБЛИЦА ПЕРЕПАКОВКИ
        --=============================================
        process(aclr, clk)
        begin
            if(aclr = '1')then
                s_odat <= (others => '0');
                s_ostb <= '0';
                s_oend <= '0';
                
            elsif(rising_edge(clk))then
                case s_path_cnt is
                    when b"01_1000" => s_odat <= s_looprg(C_OWIDTH-1 + C_SH_STEP*2 downto C_SH_STEP*2);
                    when b"01_0100" => s_odat <= s_looprg(C_OWIDTH-1 + C_SH_STEP*1 downto C_SH_STEP*1);
                    when b"01_0000" => s_odat <= s_looprg(C_OWIDTH-1 + C_SH_STEP*0 downto C_SH_STEP*0);
                    when others => NULL;
                end case;
                
                s_ostb <= s_rdstb;
                s_oend <= s_exitreg(1) or s_spctail;
                
            end if;
        end process;
    end generate big_endian_gen;
    
    
    
--=============================================
-- ПЕРЕПАКОВКА В РЕЖИМЕ LITTLE_ENDIAN
--=============================================
    little_endian_gen: if(ENDIANNESS = "LITTLE_ENDIAN") generate
        --=============================================
        -- ПРИВЕДЕНИЕ РЕГИСТРА
        --=============================================
        rgfil_gen: for i in 0 to C_RGWORDS-1 generate
            s_looprg(C_IWIDTH*(i+1)-1 downto C_IWIDTH*i) <= s_dl_slvarr(C_RGWORDS-1-i);
        end generate rgfil_gen;
        
        
        --=============================================
        -- ТАБЛИЦА ПЕРЕПАКОВКИ
        --=============================================
        process(aclr, clk)
        begin
            if(aclr = '1')then
                s_odat <= (others => '0');
                s_ostb <= '0';
                s_oend <= '0';
                
            elsif(rising_edge(clk))then
                case s_path_cnt is
                    when b"01_1000" => s_odat <= s_looprg(C_OWIDTH-1 + C_SH_STEP*0 downto C_SH_STEP*0);
                    when b"01_0100" => s_odat <= s_looprg(C_OWIDTH-1 + C_SH_STEP*1 downto C_SH_STEP*1);
                    when b"01_0000" => s_odat <= s_looprg(C_OWIDTH-1 + C_SH_STEP*2 downto C_SH_STEP*2);
                    when others => NULL;
                end case;
                
                s_ostb <= s_rdstb;
                s_oend <= s_exitreg(1) or s_spctail;
                
            end if;
        end process;
    end generate little_endian_gen;
    
    
    
--==================================
-- Назначение выходных сигналов
--==================================   
    s_iten <= oten;  
    iten <= s_iten;
    
    odat <= s_odat;
    ostb <= s_ostb;
    oend <= s_oend;
    
end Beh;
