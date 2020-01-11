--================================================================================
-- Description: sync_handler.
-- Version:     0.1.0
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
-- Ver 0.1.0  - Рабочая версия. Сигнал osync появляется через 5 тактов после 
--            ассоциированного с ним строба.
--
--
--
--
-- Additional Comments:         
-- 
-- Возможные состояния захвата, регистр s_stat_arr(0), далее значение сохраняется
-- линии задержки
-- 0b0001 - захват в первой четверти clk
-- 0b1000 - захват во второй четверти clk
-- 0b0100 - захват в третьей четверти clk
-- 0b0010 - захват в четвертой четверти clk
-- 
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
-- use work.pkg_func.all;
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
        -- flag_freq_sh: out std_logic;
        -- флаг привязки входного сигнала к фронту частоты
        flag_lock   : out std_logic
    );
end sync_handler;

architecture beh of sync_handler is

    -- восстанавливаемый сигнал
    signal  s_osync         : std_logic := '0';
    signal  s_flag_freq_sh  : std_logic := '0';
    signal  s_flag_lock_clk1x : std_logic := '0';
    
    -- сигналы для восстановления соотношения частот clk и clk2x
    signal  s_fscale        : std_logic := '0';
    signal  s_ttrig_s       : std_logic := '0';
    signal  s_ttrig_s_r     : std_logic := '0';

    -- линия задержки стадии 0
    signal  s_dl_st0        : std_logic_vector(7 downto 0) := ( others => '0' );
    signal  s_dl_fs0        : std_logic_vector(0 downto 0) := ( others => '0' );
    
    -- сигналы обработки стадии 1
    type T_STAT_ARR7 is array (0 to 6) of std_logic_vector(3 downto 0);
    signal  s_stat_arr : T_STAT_ARR7 := ( others => ( others => '0' ) );
    signal  s_stat_lock: std_logic_vector(3 downto 0) := ( others => '0' );
    signal  s_flag_lock: std_logic := '0';
    
    signal  s_stA_pres      : std_logic := '0';
    signal  s_stB_pres      : std_logic := '0';
    signal  s_stC_pres      : std_logic := '0';
    signal  s_stD_pres      : std_logic := '0';
    
    -- сигналы обработки стадии 2
    signal  s_sync_det_phase: std_logic_vector(2 downto 0) := ( others => '0' );
    signal  s_sync_det_cnt  : std_logic_vector(7 downto 0) := ( others => '0' );
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
            s_dl_fs0(0) <= s_fscale;
            s_dl_st0 <= s_dl_st0(5 downto 0) & isync_l & isync_h;
            
        end if;
    end process;


--=============================================
-- DETECTOR
--=============================================
    process(aclr, clk2x)
    begin
        if(aclr = '1')then
            s_stat_arr     <= ( others => ( others => '0' ) );
            s_sync_det_phase <= ( others => '0' );
            
        elsif(rising_edge(clk2x))then
            if( s_dl_st0(1 downto 0) = b"11" and s_dl_st0(4 downto 3) = b"00" )then
                
                case std_logic_vector'(s_dl_fs0(0) & s_dl_st0(2)) is      
                    when b"00" => s_stat_arr(0) <= b"0001";
                    when b"01" => s_stat_arr(0) <= b"0010";
                    when b"10" => s_stat_arr(0) <= b"0100";
                    when b"11" => s_stat_arr(0) <= b"1000";
                    when others => s_stat_arr(0) <= b"1111";
                end case;
                
                s_stat_arr(1) <= s_stat_arr(0);
                s_stat_arr(2) <= s_stat_arr(1);
                s_stat_arr(3) <= s_stat_arr(2);
                s_stat_arr(4) <= s_stat_arr(3);
                s_stat_arr(5) <= s_stat_arr(4);
                s_stat_arr(6) <= s_stat_arr(5);
                
            end if;
            
            if( s_dl_st0(1 downto 0) = b"11" and s_dl_st0(4 downto 3) = b"00" )then
                s_sync_det_phase <= b"001";
            else
                s_sync_det_phase <= s_sync_det_phase(1 downto 0) & '0';
            end if;
            
            
        end if;
    end process;


--=============================================
-- LOCK HANDLER
--=============================================
    s_stA_pres <= s_stat_arr(0)(0) or s_stat_arr(1)(0) or s_stat_arr(2)(0) or s_stat_arr(3)(0) or s_stat_arr(4)(0) or s_stat_arr(5)(0) or s_stat_arr(6)(0);
    s_stB_pres <= s_stat_arr(0)(1) or s_stat_arr(1)(1) or s_stat_arr(2)(1) or s_stat_arr(3)(1) or s_stat_arr(4)(1) or s_stat_arr(5)(1) or s_stat_arr(6)(1);
    s_stC_pres <= s_stat_arr(0)(2) or s_stat_arr(1)(2) or s_stat_arr(2)(2) or s_stat_arr(3)(2) or s_stat_arr(4)(2) or s_stat_arr(5)(2) or s_stat_arr(6)(2);
    s_stD_pres <= s_stat_arr(0)(3) or s_stat_arr(1)(3) or s_stat_arr(2)(3) or s_stat_arr(3)(3) or s_stat_arr(4)(3) or s_stat_arr(5)(3) or s_stat_arr(6)(3);
    
    
    process(aclr, clk2x)
    begin
        if(aclr = '1')then
            s_stat_lock <= ( others => '0' );
            s_flag_lock <= '0';
            
            s_sync_det_cnt <= ( others => '0' );
            s_sync_det_stb <= '0';
        elsif(rising_edge(clk2x))then
        
            if( s_sync_det_phase(0) = '1' )then
                if( s_flag_lock = '0' )then
                    s_stat_lock <= s_stat_arr(0);
                end if;
            end if;
                
            if( s_sync_det_phase(1) = '1' )then
            
                case s_stat_lock is
                    when b"0001" => 
                        if( ( s_stD_pres and s_stB_pres ) = '0' and s_stC_pres = '0' ) then 
                            s_flag_lock <= '1';
                        else
                            s_flag_lock <= '0';
                        end if;
                        
                    when b"0010" => 
                        if( ( s_stA_pres and s_stC_pres ) = '0' and s_stD_pres = '0' ) then 
                            s_flag_lock <= '1';
                        else
                            s_flag_lock <= '0';
                        end if;
                        
                    when b"0100" => 
                        if( ( s_stB_pres and s_stD_pres ) = '0' and s_stA_pres = '0' ) then 
                            s_flag_lock <= '1';
                        else
                            s_flag_lock <= '0';
                        end if;
                        
                    when b"1000" => 
                        if( ( s_stC_pres and s_stA_pres ) = '0' and s_stB_pres = '0' ) then 
                            s_flag_lock <= '1';
                        else
                            s_flag_lock <= '0';
                        end if;
                        
                    when others => s_flag_lock <= '0';
                    
                end case;
                
            end if;
            
            
            -- обработка с учетом состояния s_stat_lock
            if( s_sync_det_phase(2) = '1' )then
                if( s_flag_lock = '0' )then
                    case s_stat_arr(0) is
                        when b"0001" => s_sync_det_cnt <= b"00111111";
                        when b"0010" => s_sync_det_cnt <= b"00111111";
                        when b"0100" => s_sync_det_cnt <= b"00011111";
                        when b"1000" => s_sync_det_cnt <= b"00011111";
                        
                        when others  => s_sync_det_cnt <= b"00111111";
                    end case;
                    
                else
                    
                    case s_stat_lock is
                        when b"0001" =>
                            if( s_stat_arr(0) = b"0010" ) then
                                s_sync_det_cnt <= b"00111111";
                            elsif( s_stat_arr(0) = b"0001" ) then
                                s_sync_det_cnt <= b"00111111";
                            elsif( s_stat_arr(0) = b"1000" ) then
                                s_sync_det_cnt <= b"01111111";
                            end if;
                            
                        when b"0010" =>
                            if( s_stat_arr(0) = b"0100" ) then
                                s_sync_det_cnt <= b"00011111";
                            elsif( s_stat_arr(0) = b"0010" ) then
                                s_sync_det_cnt <= b"00111111";
                            elsif( s_stat_arr(0) = b"0001" ) then
                                s_sync_det_cnt <= b"00111111";
                            end if;
                            
                        when b"0100" =>
                            if( s_stat_arr(0) = b"1000" ) then
                                s_sync_det_cnt <= b"00011111";
                            elsif( s_stat_arr(0) = b"0100" ) then
                                s_sync_det_cnt <= b"00011111";
                            elsif( s_stat_arr(0) = b"0010" ) then
                                s_sync_det_cnt <= b"00111111";
                            end if;
                            
                        when b"1000" =>
                            if( s_stat_arr(0) = b"0001" ) then
                                s_sync_det_cnt <= b"00001111";
                            elsif( s_stat_arr(0) = b"1000" ) then
                                s_sync_det_cnt <= b"00111111";
                            elsif( s_stat_arr(0) = b"0100" ) then
                                s_sync_det_cnt <= b"00011111";
                            end if;
                        
                        when others => s_sync_det_cnt <= b"00111111";
                        
                    end case;
                    
                end if;
                
            else
                s_sync_det_cnt <= s_sync_det_cnt(6 downto 0) & '0';
            end if;
            
            s_sync_det_stb <= s_sync_det_cnt(7);
            
            --=======================================================
            -- тестовый блок, калибровка базовых задержек
            -- if( s_sync_det_phase(2) = '1' )then
                -- case s_stat_arr(0) is
                    -- when b"0001" =>
                        -- s_sync_det_cnt <= b"00111111";
                        
                    -- when b"0010" =>
                        -- s_sync_det_cnt <= b"00111111";
                        
                    -- when b"0100" =>
                        -- s_sync_det_cnt <= b"00011111";
                        
                    -- when b"1000" =>
                        -- s_sync_det_cnt <= b"00011111";
                    
                    -- when others => s_sync_det_cnt <= b"00111111";
                    
                -- end case;
            -- else
                -- s_sync_det_cnt <= s_sync_det_cnt(6 downto 0) & '0';
            -- end if;
            --=======================================================
            
        end if;
    end process;
    
    
--==========================================================================
-- OUTPUT
--==========================================================================   
    process(clk, aclr)
    begin
        if (aclr = '1') then
            s_osync <= '0';
            s_flag_lock_clk1x <= '0';
        elsif(rising_edge(clk)) then
            s_osync <= s_sync_det_stb;
            s_flag_lock_clk1x <= s_flag_lock;
        end if;
    end process;
    
    
--=============================================
-- OUTPUT ASSIGMENTS
--=============================================
    osync <= s_osync;
    --flag_freq_sh <= s_flag_freq_sh;
    flag_lock <= s_flag_lock_clk1x;
    
END beh;
