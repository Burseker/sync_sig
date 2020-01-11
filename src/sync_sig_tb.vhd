--=============================
-- Developed by SVB. Ver. 0.0.0 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Сергей Бураков
--                  
-- Create Date:     15:33 21.11.2012 
-- Design Name:     
-- Tool versions:   modelsim 10.2d
-- Description:     
--                  
-- Revision:        
-- Revision 0.0.0 - Создание файла.
--                  
--                  
-- Additional Comments:         
-- 
-- 
----------------------------------------------------------------------------------
-- 
--============================================
--====   LIBS   ==============================
--============================================

--=== file rw lib ===
library modelsim_lib;
use modelsim_lib.util.all;
--=========================

--=== basic lib ===
library ieee;                                               
use ieee.std_logic_1164.all;

--=== std logic lib ===
-- USE IEEE.STD_LOGIC_ARITH.ALL;
-- USE IEEE.STD_LOGIC_UNSIGNED.ALL;

--=== numeric std lib ===
use ieee.numeric_std.all;

--=== common lib ===
-- use work.qpkt_pkg.all;
use work.pkg_func.all;
-- use work.qpkt_imit_pkg.all;

entity sync_sig_tb is
end sync_sig_tb;

architecture beh of sync_sig_tb is
    
    constant C_CLK_PERIOD       : time := 10 ns;
    constant C_CLKA_PERIOD      : time := 5 ns;
    constant C_CLKB_PERIOD      : time := 20 ns;
    constant C_CLKC_PERIOD      : time := 20010 ps;
    -- constant C_CRC2_PERIOD  : time := 20 ns;
    -- constant C_CRC4_PERIOD  : time := 40 ns;
    
    -- служебные сигналы
    signal  aclr        : std_logic := '1';
    signal  test_rst    : std_logic := '1';
    signal  aclr_uut    : std_logic := '1';
    signal  clk         : std_logic := '1';
    signal  clka        : std_logic := '1';
    signal  clkb        : std_logic := '1';
    signal  clkc        : std_logic := '1';
    
    signal  ureal_time      : unsigned( 31 downto 0 ) := ( others => '0' );
    signal  real_time       : std_logic_vector( 31 downto 0 ) := ( others => '0' );

    -- восстанавливаемый сигнал
    signal  s_sync0_stb     : std_logic := '0';
    signal  s_sync0_cnt     : unsigned( 3 downto 0 ) := ( others => '0' );
    signal  sync        : std_logic := '0';
    
--============================================
--============================================
--============================================
--============================================
--============================================
--============================================
--============================================


begin
    --=============================================
    -- СИГНАЛЫ СИНХРОНИЗАЦИИ ДЛЯ ИМИТАТОРА ШИНЫ АЦП
    --=============================================    
    aclr  <= '0' after 10*C_CLK_PERIOD;
    
    clk <= not clk after C_CLK_PERIOD/2;
    
    clka <= not clka after C_CLKA_PERIOD/2;
    clkb <= not clkb after C_CLKB_PERIOD/2;
    clkc <= not clkc after C_CLKC_PERIOD/2;
    --sysclk2 <= not sysclk2 after 1 ns;
    -- clk50 <= not clk50 when rising_edge(clk100);
    -- clk25 <= not clk25 when rising_edge(clk50);
    
    --=============================================
    -- СЧЕТЧИК РЕАЛЬНОГО ВРЕМЕНИ
    --=============================================
    ureal_time <= ureal_time + 1 after C_CLK_PERIOD;
    real_time <= std_logic_vector(ureal_time);
    
    process(aclr, clkc)
    begin
        if(aclr = '1')then
            s_sync0_stb <= '0';
            s_sync0_cnt <= x"0";
        elsif(rising_edge(clkc))then
        
            if( s_sync0_cnt = x"F" ) then s_sync0_cnt <= x"0";
            else s_sync0_cnt <= s_sync0_cnt + 1; end if;
            
            if( s_sync0_cnt = x"F" )then
                s_sync0_stb <= '1';
            else
                s_sync0_stb <= '0';
            end if;
        end if;
    end process;
    
    sync <= s_sync0_stb;
    
    --XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    --=============================================
    --=============================================
    --=============================================
    --=============================================
    -- DMA UUT
    --=============================================
    --=============================================
    --=============================================
    --=============================================
    --XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    test_rst <= '1' when real_time > x"0000_0B10" and real_time < x"0000_0B1F" else '0';
    aclr_uut <= aclr or test_rst;
    
    sync_sig_uut: entity work.sync_sig_top
    generic map( SIM => 0 )
    port map(
        aclr    => aclr_uut,
        clk     => clk,
        clka    => clka,
        clkb    => clkb,
        clkc    => clkc,
        sync    => sync
    );

    
END beh;
