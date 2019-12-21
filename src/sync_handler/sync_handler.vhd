--================================================================================
-- Description: sync_handler.
-- Version:     0.0.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
--
-- Keywords:    
-- Tools:       
--            
-- Details:
--               
-- Version History:   
-- Ver 0.0.0  - Initial version
--
--
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

entity sync_handler is
    generic (
        SIM     : integer := 0
    );
    port (
        aclr        : in  std_logic;
        -- очищенный от джиттера тактовый сигнал 105Мгц
        clk         : in  std_logic;
        clk2x       : in  std_logic;
        -- строб начала запуска, несинхронизированный, защелкивается в DDR регистре
        isync_h     : in  std_logic;
        isync_l     : in  std_logic;
        
        -- строб начала запуска, синхронизированный с clk
        osync       : out std_logic;
        
        -- флаги состояния
        -- флаг ухода частоты
        flag_freq_sh: out std_logic
    );
end sync_handler;

architecture beh of sync_handler is

    -- восстанавливаемый сигнал
    signal  s_sync0_stb     : std_logic := '0';
    signal  s_sync0_cnt     : unsigned( 3 downto 0 ) := ( others => '0' );
    signal  sync            : std_logic := '0';
    
    signal  s_osync         : std_logic := '0';
    signal  s_flag_freq_sh  : std_logic := '0';
    
    signal  s_fscale        : std_logic := '0';
    signal  s_ttrig_s       : std_logic := '0';
    signal  s_ttrig_s_r     : std_logic := '0';

    signal  s_dl_st0        : std_logic_vector(7 downto 0) := ( others => '0' );
    signal  s_dl_fs0        : std_logic_vector(3 downto 0) := ( others => '0' );
    
    signal  s_sync_stat     : std_logic_vector(1 downto 0) := ( others => '0' );
    signal  s_sync_stat_r   : std_logic_vector(1 downto 0) := ( others => '0' );
    signal  s_sync_stat_rr  : std_logic_vector(1 downto 0) := ( others => '0' );
    
    signal  s_sync_det_cnt  : std_logic_vector(3 downto 0) := ( others => '0' );
    signal  s_sync_det_stb  : std_logic := '0';
    
begin

 --==========================================================================
-- T trigger
--==========================================================================   
    process(clk, aclr)
    begin
        if (aclr = '1') then
            s_ttrig_s <= '0';
        elsif(rising_edge(clk)) then
            s_ttrig_s <= not s_ttrig_s;
        end if;
    end process;
    
    
 --==========================================================================
-- freq relation detector
--==========================================================================   
    process(clk2x, aclr)
    begin
        if (aclr = '1') then
            s_ttrig_s_r <= '0';
            s_fscale    <= '0';
            
        elsif(rising_edge(clk2x)) then
            s_ttrig_s_r <= s_ttrig_s;
            if((s_ttrig_s and not s_ttrig_s_r) = '1')then
                s_fscale <= '0';
            else
                s_fscale <= not s_fscale;
            end if;
            
        end if;
    end process;
    
    
--=============================================
-- DELAY LINES
--=============================================;
    process(aclr, clk2x)
    begin
        if(aclr = '1')then
            s_dl_fs0 <= ( others => '0' );
            s_dl_st0 <= ( others => '0' );
            
        elsif(rising_edge(clk2x))then
            s_dl_fs0 <= s_dl_fs0(2 downto 0) & s_fscale;
            s_dl_st0 <= s_dl_st0(5 downto 0) & isync_l & isync_h;
            
        end if;
    end process;


--=============================================
-- DETECTOR
--=============================================
    process(aclr, clk2x)
    begin
        if(aclr = '1')then
            s_sync_stat    <= ( others => '0' );
            s_sync_stat_r  <= ( others => '0' );
            s_sync_stat_rr <= ( others => '0' );
            
            s_sync_det_cnt <= ( others => '0' );
            s_sync_det_stb <= '0';
            
        elsif(rising_edge(clk2x))then
            if( s_dl_st0(1 downto 0) = b"11" and s_dl_st0(4 downto 3) = b"00" )then
                s_sync_stat   <= s_dl_fs0(1) & s_dl_st0(2);
                s_sync_stat_r <= s_sync_stat;
                s_sync_stat_rr <= s_sync_stat_r;
            end if;
            
            if( s_dl_st0(1 downto 0) = b"11" and s_dl_st0(4 downto 3) = b"00" )then
                s_sync_det_cnt <= ( others => '1' );
            else
                s_sync_det_cnt <= s_sync_det_cnt(2 downto 0) & '0';
            end if;
            
            s_sync_det_stb <= s_sync_det_cnt(3);
            
        end if;
    end process;


--==========================================================================
-- OUTPUT
--==========================================================================   
    process(clk, aclr)
    begin
        if (aclr = '1') then
            s_osync <= '0';
        elsif(rising_edge(clk)) then
            s_osync <= s_sync_det_stb;
        end if;
    end process;
    
    
--=============================================
-- OUTPUT ASSIGMENTS
--=============================================
    osync <= s_osync;
    flag_freq_sh <= s_flag_freq_sh;
    
END beh;
