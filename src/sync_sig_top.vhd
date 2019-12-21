--================================================================================
-- Description: Верхний уровень отладочного проекта sync_sig
-- Version:     0.0.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    sync_sig
-- Tools:       modelsim 10.2d
--              
-- Note:
-- 
-- Version History:
-- Ver 0.0.0 - File create
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=========================
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
--=========================

entity sync_sig_top is
    generic (
        SIM     : integer := 0
    );
    port (
        aclr        : in  std_logic;
        clk         : in  std_logic;
        clka        : in  std_logic;
        clkb        : in  std_logic;
        clkc        : in  std_logic;
        sync        : in  std_logic
    );
end sync_sig_top;

architecture beh of sync_sig_top is

    signal s_ddrsync_h      : std_logic := '0';
    signal s_ddrsync_l      : std_logic := '0';
    
    signal osync            : std_logic := '0';
    signal s_flag_freq_sh   : std_logic := '0';
    
--=============================================
-- OTHERS
--=============================================
    -- service signals
    signal s_rtime          : unsigned(31 downto 0) := (others => '0');
    signal s_rtime_aux      : unsigned(31 downto 0) := (others => '0');
    
    signal s_adcimit_dat    : std_logic_vector(15 downto 0) := (others => '0');
    signal s_adcimit_or     : std_logic := '0';
    signal s_latch_rst      : std_logic := '0';
    signal s_new_dist       : std_logic := '0';
    
    
begin
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    -- process(aclr, clk)
    -- begin
        -- if(aclr = '1')then
        -- elsif(rising_edge(clk))then
        -- end if;
    -- end process;
    
    
    
--==========================================================================
-- Входной DDR-триггер
--==========================================================================
    sync_ddr: altddio_in
    GENERIC MAP (
		intended_device_family => "Stratix II",
		--invert_input_clocks => "ON",
		invert_input_clocks => "OFF",
		lpm_type => "altddio_in",
		width => 1
	)
	PORT MAP (
		aclr        => aclr,
		inclock     => clka,
		datain(0)   => sync,
		dataout_h(0)=> s_ddrsync_h,
		dataout_l(0)=> s_ddrsync_l
	);
    
 
--==========================================================================
-- ЗАХВАТ SYNC
--========================================================================== 
    sync_handler: entity work.sync_handler
    port map(
        aclr         => aclr,
        -- очищенный от джиттера тактовый сигнал 105Мгц
        clk          => clk,
        clk2x        => clka,
        -- строб начала запуска, несинхронизированный, защелкивается в DDR регистре
        isync_h      => s_ddrsync_h,
        isync_l      => s_ddrsync_l,
        
        -- строб начала запуска, синхронизированный с clk
        osync        => osync,
        
        -- флаги состояния
        -- флаг ухода частоты
        flag_freq_sh => s_flag_freq_sh
    );
    
    
--=============================================
-- OUTPUT ASSIGMENTS
--=============================================
    
    
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_rtime <= (others => '0');
        elsif(rising_edge(clk))then
            -- if( s_rtime = (s_rtime'range => '1') )then
            if( s_rtime = x"0F00" )then
                s_rtime <= (others => '0');
            else
                s_rtime <= s_rtime + 1;
            end if;
        end if;
    end process;
    
    s_latch_rst   <= '1' when s_rtime_aux(15 downto 0) = x"34C3" else '0';
    s_new_dist    <= '1' when s_rtime(15 downto 0) = x"0E80" else '0';
    
    
    
end beh;
