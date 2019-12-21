--================================================================================
-- Description: Битовый согласованный фильтр.
-- Version:     0.3.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    im_sync
-- Tools:       Altera Quartus 9.1 SP1
--              
-- Details: 
-- 
-- Version History:
-- Ver 0.0.0 - File created
-- Ver 0.1.0 - Debug version
-- Ver 0.2.0 - Добавлена возможность нахождения максимума без рассчета суммы для
--             32-х разрядного паттерна.
-- Ver 0.3.0 - Выходной сигнал res_max стробируется
--
-- 
----------------------------------------------------------------------------------
--=========================
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=========================

--=========================
use work.pkg_sim.all;
use work.pkg_func.all;
-- use work.qpkt_pkg.all;
-- use work.lp_pkg.all;
--=========================

entity bit_matched_filter is
generic
(
    PATTERN     : std_logic_vector;
    RES_WIDTH   : natural;
    SUMM_ENA    : boolean := true
);
port
(
    aclr    : in  std_logic;
    clk     : in  std_logic;
    
    -- Вход модулированного сигнала
    idat    : in  std_logic;
    istb    : in  std_logic;
    
    res     : out std_logic_vector(RES_WIDTH-1 downto 0);
    res_max : out std_logic
);
end bit_matched_filter;


architecture beh of bit_matched_filter is
    
    constant C_DELAY_LINE_WIDTH : integer := PATTERN'length;
    constant C_FILTER_RES_WIDTH : integer := 2 + log2_ceil(C_DELAY_LINE_WIDTH);
    
    signal s_delay_line : std_logic_vector(C_DELAY_LINE_WIDTH-2 downto 0) := (others => '1');
    signal s_mult_res   : std_logic_vector(C_DELAY_LINE_WIDTH-1 downto 0) := (others => '1');
    
    signal s_summ_res   : std_logic_vector(RES_WIDTH-1 downto 0) := (others => '0');
    signal s_st5_res    : std_logic := '0';
    signal s_res_max    : std_logic := '0';
    
begin
    
    
    --==========================================================================
    -- линия задержки
    --==========================================================================
    process(clk, aclr)
    begin
        if (aclr = '1') then
            s_delay_line <= (others => '1');
        elsif(rising_edge(clk)) then
            if( istb = '1' )then
                s_delay_line(0) <= idat;
                s_delay_line(C_DELAY_LINE_WIDTH-2 downto 1) <= s_delay_line(C_DELAY_LINE_WIDTH-3 downto 0);
            end if;
        end if;
    end process;
    
    --==========================================================================
    -- умножение на коэффициенты фильтра
    --==========================================================================
    process(clk, aclr)
    begin
        if (aclr = '1') then
            s_mult_res <= (others => '1');
        elsif(rising_edge(clk)) then
            if( istb = '1' )then
                s_mult_res(0) <= idat xor PATTERN(C_DELAY_LINE_WIDTH-1);
                for i in 1 to C_DELAY_LINE_WIDTH-1 loop
                    s_mult_res(i) <= s_delay_line(i-1) xor PATTERN(C_DELAY_LINE_WIDTH-1-i);
                end loop;
            end if;
        end if;
    end process;
    
    treshold_max_gen: if( SUMM_ENA = false ) generate
    signal s_st1_res    : std_logic_vector(15 downto 0) := (others => '1');
    signal s_st2_res    : std_logic_vector(7 downto 0) := (others => '1');
    signal s_st3_res    : std_logic_vector(3 downto 0) := (others => '1');
    signal s_st4_res    : std_logic_vector(1 downto 0) := (others => '1');
    begin
        --==========================================================================
        -- Поиск максимума для 32-х разрядного паттерна
        --==========================================================================
        process(clk, aclr)
        begin
            if (aclr = '1') then
                s_st1_res <= (others => '1');
                s_st2_res <= (others => '1');
                s_st3_res <= (others => '1');
                s_st4_res <= (others => '1');
                s_st5_res <= '0';
                s_res_max <= '0';
            elsif(rising_edge(clk)) then
                --if( istb = '1' )then
                    for i in 0 to 15 loop
                        -- if( s_mult_res(4*(i+1)-1 downto 4*i) = x"F" )then s_st1_res(i) <= '1';
                        -- else s_st1_res(i) <= '0'; end if;
                        s_st1_res(i) <= s_mult_res(2*i+1) or s_mult_res(2*i);
                    end loop;
                    
                    for i in 0 to 7 loop
                        -- if( s_mult_res(4*(i+1)-1 downto 4*i) = x"F" )then s_st1_res(i) <= '1';
                        -- else s_st1_res(i) <= '0'; end if;
                        s_st2_res(i) <= s_st1_res(2*i+1) or s_st1_res(2*i);
                    end loop;
                    
                    for i in 0 to 3 loop
                        -- if( s_st2_res(4*(i+1)-1 downto 4*i) = x"F" )then s_st2_res(i) <= '1';
                        -- else s_st2_res(i) <= '0'; end if;
                        s_st3_res(i) <= s_st2_res(2*i+1) or s_st2_res(2*i);
                    end loop;
                    
                    for i in 0 to 1 loop
                        -- if( s_st2_res(4*(i+1)-1 downto 4*i) = x"F" )then s_st2_res(i) <= '1';
                        -- else s_st2_res(i) <= '0'; end if;
                        s_st4_res(i) <= s_st3_res(2*i+1) or s_st3_res(2*i);
                    end loop;
                    
                    s_st5_res <= not(s_st4_res(1) or s_st4_res(0));
                --end if;
                s_res_max <= s_st5_res and istb;
            end if;
        end process;
    
    end generate;
    
    
    treshold_summ_gen: if( SUMM_ENA = true ) generate
    signal s_summ_input : std_logic_vector(2*C_DELAY_LINE_WIDTH-1 downto 0) := (others => '0');
    begin
        --==========================================================================
        -- Формирование входного вектора для сумматора
        --==========================================================================
        adder_in_gen : for i in 0 to C_DELAY_LINE_WIDTH-1 generate
            -- Каждый разряд результата xor представляем в виде 2-разрядного числа
            -- со знаком. Знаковый разряд такого числа равен результату перемножения,
            -- а младший всегда равен единице.
            -- '0' -> "01" = +1
            -- '1' -> "11" = -1
            s_summ_input(2*i+1) <= s_mult_res(i);
            s_summ_input(2*i+0) <= '1';
        end generate;

        
        --==========================================================================
        -- Сумматор
        --==========================================================================
        adder_inst : entity work.par_add
        generic map(
            SWIDTH => 2,--Разрядность одного слагаемого
            SNUM   => C_DELAY_LINE_WIDTH)--Число слагаемых
        port map(
            aclr   => aclr,
            clk    => clk,
            ena    => '1',
            sums   => s_summ_input,
            res    => s_summ_res
        );
    end generate;
    
    --==========================================================================
    -- Назначение выходных сигналов
    --==========================================================================
    res <= s_summ_res;
    res_max <= s_res_max;
end beh;
