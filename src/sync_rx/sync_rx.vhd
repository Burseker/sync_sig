--==============================================================================
-- Description: Приемник фазоманипулированного двухчатотного сигнала SYNC
-- Version:     0.1.0
-- Developer:   SVB
-- Workgroup:   IRS16
--==============================================================================
-- Keywords:    sync_rx
-- Tools:       Altera Quartus 9.1 SP1
--              
-- Details: Блок является верхним уровнем приемника сообщений,
-- передаваемых по однопроводной линии с использованием
-- фазовой манипуляции. В качестве несущей используются 2 ортогональные частоты
-- 210МГц и 105Мгц. На 210МГц передается синхропоследовательность ПСП,
-- на 105МГц передаются данные.
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--  Можно доработать блок выбора канала, а так же дополнить алгоритм выбора
-- канала схемой счета фронтов. 
--  Так же в блоке оставлена куча отладочных регистров. Возможно их надо будет
-- выпилить.
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
-- Version History:
-- Ver 0.0.0 - File created
-- Ver 0.1.0 - Исправлен ряд ошибок приема ПСП, а так же восстановления стробов
--             синхронизации. 
--
-- 
--==============================================================================

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

--=========================
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
--=========================

entity sync_rx is
port
(
  clk_420MHz : in std_logic;
  clk_105MHz : in std_logic;
  aclr       : in std_logic;
  
  sync_in    : in std_logic;
  
  -- Выходы тактируются частотой 105 МГц
  synch_ok   : out std_logic;
  time_dat   : out std_logic_vector(31 downto 0);
  time_stb   : out std_logic;
  
  trh_rst    : in std_logic;
  -- Выходы тактируются частотой 105 МГц
  sync_dat   : out std_logic_vector(15 downto 0);
  sync_stb   : out std_logic;
  sync_qstr  : out std_logic;
  sync_qend  : out std_logic
);
end sync_rx;

architecture impl of sync_rx is

    constant C_CHAN_NUM         : integer := 4;
    constant C_SYNCHRO_MSG      : std_logic_vector(31 downto 0) := x"5A89F061";
    constant C_BITMF_RES_WIDTH  : integer := 7;
    
    signal s_ddrsync_h  : std_logic := '0';
    signal s_ddrsync_l  : std_logic := '0';
    
    signal s_fmsg_ph    : std_logic_vector(C_CHAN_NUM-1 downto 0) := (others => '0');
    signal s_fmsg_stb   : std_logic_vector(C_CHAN_NUM-1 downto 0) := (others => '0');
    signal s_smsg_ph    : std_logic_vector(2*C_CHAN_NUM-1 downto 0) := (others => '0');
    
    type t_bitmf_res is array (natural range <>) of std_logic_vector(C_BITMF_RES_WIDTH-1 downto 0);
    signal s_bitmf_res : t_bitmf_res(C_CHAN_NUM-1 downto 0) := (others => (others => '0'));
    signal s_bitmf_res_latch : t_bitmf_res(C_CHAN_NUM-1 downto 0) := (others => (others => '0'));
    signal s_bitmf_res_latch_r : t_bitmf_res(C_CHAN_NUM-1 downto 0) := (others => (others => '0'));
    signal s_bitmf_res_latch_rr : t_bitmf_res(C_CHAN_NUM-1 downto 0) := (others => (others => '0'));
    
    -- sinals 420MGz
    signal s_carr_f     : std_logic := '0';
    signal s_carr_s     : std_logic := '0';
    signal s_carr_s_r   : std_logic := '0';
    signal s_ttrig_s_r  : std_logic := '0';
    --signal s_carr_f_fl: std_logic := '0';
    signal s_fscale     : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_obt    : std_logic_vector(3 downto 0) := (others => '0');
    signal s_sync_str   : std_logic := '0';
    signal s_sync_str_vbr   : std_logic := '0';
    type t_trh_vbr is array (natural range <>) of std_logic_vector(5 downto 0);
    signal s_trh_vbr    : t_trh_vbr(3 downto 0) := (others => (others => '0'));
    
    signal s_slow_stb   : std_logic_vector(3 downto 0) := (others => '0');
    signal s_datmsg_mux : std_logic := '0';
    signal s_errmsg_mux : std_logic := '0';
    signal s_datmsg_slow : std_logic := '0';
    signal s_errmsg_slow : std_logic := '0';
    signal s_strmsg_slow : std_logic := '0';
    signal s_err_blank   : std_logic := '1';
    
    
    signal s_fastmux_adr: std_logic_vector(1 downto 0) := (others => '0');
    signal s_fastmux_sw : std_logic := '0';
    signal s_fastmux_st1: std_logic_vector(3 downto 0) := (others => '0');
    signal s_fastmux_st2: std_logic_vector(1 downto 0) := (others => '0');
    type t_fastmux_dl is array (natural range <>) of std_logic_vector(1 downto 0);
    signal s_fastmux_dl : t_fastmux_dl(4 downto 0) := (others => (others => '0'));
    
    -- sinals 105MGz
    signal s_ttrig_s    : std_logic := '0';
    signal s_trh_obt_s  : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_obt_s_r: std_logic_vector(3 downto 0) := (others => '0');
    type t_trh_cnt is array (natural range <>) of unsigned(3 downto 0);
    signal s_trh_cnt    : t_trh_cnt(3 downto 0) := (others => (others => '0'));
    signal s_max_path   : natural range 0 to 3 := 0;
    signal s_path       : natural range 0 to 3 := 0;
    signal s_trh_chek   : std_logic := '0';
    signal s_trh_good       : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_good_fail  : std_logic_vector(3 downto 0) := (others => '0');
    
    signal s_cdc_dat    : std_logic := '0';
    signal s_cdc_err    : std_logic := '0';
    signal s_cdc_sstr   : std_logic := '0';
    
    signal s_qcnt       : unsigned(7 downto 0) := (others => '0');
    signal s_ser_dat    : std_logic_vector(15 downto 0) := (others => '0');
    signal s_ser_err    : std_logic := '0';
    signal s_ser_stb    : std_logic := '0';
    signal s_ser_sync   : std_logic := '0';
    signal s_ser_time   : std_logic := '0';
    signal s_ser_qstr   : std_logic := '0';
    signal s_ser_qend   : std_logic := '0';
    
    signal s_crc_dat    : std_logic_vector(15 downto 0) := (others => '0');
    signal s_time_rec   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_time_stb   : std_logic := '0';
    
    
    -- DEBUG SIGNALS
    attribute noprune: boolean;
    
    signal s_trh_cnt_r          : t_trh_cnt(3 downto 0) := (others => (others => '0'));
    signal s_path_r             : natural range 0 to 3 := 0;
    signal s_trh_good_r         : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_good_fail_r    : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_cnt_rr         : t_trh_cnt(3 downto 0) := (others => (others => '0'));
    signal s_path_rr            : natural range 0 to 3 := 0;
    signal s_trh_good_rr        : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_good_fail_rr   : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_obt_s_rr       : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_obt_s_rrr      : std_logic_vector(3 downto 0) := (others => '0');
    signal s_trh_obt_s_rrr_catch: std_logic := '0';
    signal s_del_late_str       : std_logic_vector(63 downto 0) := (others => '0');
    
    attribute noprune of s_trh_cnt_rr : signal is true;
    attribute noprune of s_path_rr : signal is true;
    attribute noprune of s_trh_good_rr : signal is true;
    attribute noprune of s_trh_good_fail_rr : signal is true;
    attribute noprune of s_trh_obt_s_rrr : signal is true;
    attribute noprune of s_trh_obt_s_rrr_catch : signal is true;
    attribute noprune of s_bitmf_res_latch_rr : signal is true;
    
begin

    --==========================================================================
    -- strob generator
    --==========================================================================   
    process(clk_105MHz)
    begin
        if (rising_edge(clk_105MHz)) then
            s_trh_cnt_r <= s_trh_cnt;
            s_trh_cnt_rr <= s_trh_cnt_r;
            s_path_r <= s_path;
            s_path_rr <= s_path_r;
            s_trh_good_r <= s_trh_good;
            s_trh_good_rr <= s_trh_good_r;
            s_trh_good_fail_r <= s_trh_good_fail;
            s_trh_good_fail_rr <= s_trh_good_fail_r;
            s_trh_obt_s_rr <= s_trh_obt_s_r;
            s_trh_obt_s_rrr <= s_trh_obt_s_rr;
            s_trh_obt_s_rrr_catch <= or_bus(s_trh_obt_s_rr);
            s_del_late_str(0) <= s_trh_obt_s_rrr_catch;
            s_del_late_str(63 downto 1) <= s_del_late_str(62 downto 0);
            
            s_bitmf_res_latch_r <= s_bitmf_res_latch;
            s_bitmf_res_latch_rr <= s_bitmf_res_latch_r;
        end if;
    end process;    
    
    
    --==========================================================================
    -- strob generator
    --==========================================================================
    process(clk_420MHz, aclr)
    begin
        if (aclr = '1') then
            s_carr_f    <= '0';
            s_carr_s    <= '0';
            s_carr_s_r  <= '0';
            s_ttrig_s_r  <= '0';
            s_fscale    <= (others => '0');
        elsif(rising_edge(clk_420MHz)) then
            s_carr_f    <= s_fscale(1) or s_fscale(3);
            
            if(s_fscale(1) = '1')then s_carr_s      <= '1';
            elsif( s_fscale(3) = '1')then s_carr_s  <= '0';
            end if;
            s_carr_s_r <= s_carr_s;
            
            s_ttrig_s_r  <= s_ttrig_s;
            if((s_ttrig_s and not s_ttrig_s_r) = '1')then
                s_fscale <= b"0010";
            else
                s_fscale(3 downto 1) <= s_fscale(2 downto 0);
                s_fscale(0) <= s_fscale(3);
            end if;
            
        end if;
    end process;    
    
    
    --==========================================================================
    -- strob generator
    --==========================================================================   
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_ttrig_s <= '0';
        elsif(rising_edge(clk_105MHz)) then
            s_ttrig_s <= not s_ttrig_s;
        end if;
    end process;    
    

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
		inclock     => clk_420MHz,
		datain(0)   => sync_in,
		dataout_h(0)=> s_ddrsync_h,
		dataout_l(0)=> s_ddrsync_l
	);
    
    
    
    --==========================================================================
    -- отладочные блоки преобразования последовательности SYNC на 105Мгц
    --========================================================================== 
    ser_dc_conv0 :entity work.sync_dc_shiftreg
    port map
    (
        clk_420MHz => clk_420MHz,
        clk_105MHz => clk_105MHz,
        aclr       => aclr,

        sync       => s_ddrsync_h,
        prns_str   => s_del_late_str(63),

        sync_dat   => open,
        sync_stb   => open
    );
    
    ser_dc_conv1 :entity work.sync_dc_shiftreg
    port map
    (
        clk_420MHz => clk_420MHz,
        clk_105MHz => clk_105MHz,
        aclr       => aclr,

        sync       => s_ddrsync_l,
        prns_str   => s_del_late_str(63),

        sync_dat   => open,
        sync_stb   => open
    );

    
    --==========================================================================
    -- Демодулятор для сигнала захваченного по фронту
    --==========================================================================    
    sync_phase_demod_h:entity work.sync_phase_demodulator
    port map
    (
        aclr      => aclr,
        clk420    => clk_420MHz,
        -- Вход модулированного сигнала
        sync_dat  => s_ddrsync_h,
        fmsg_stb  => s_carr_f,
        smsg_stb  => s_carr_s,
        -- битовый поток данных
        fmsg_ph1  => s_fmsg_ph(0),
        fmsg_ph2  => s_fmsg_ph(1),

        smsg_ph11 => s_smsg_ph(0),
        smsg_ph12 => s_smsg_ph(1),
        smsg_ph21 => s_smsg_ph(2),
        smsg_ph22 => s_smsg_ph(3)
    );
    
    --==========================================================================
    -- Демодулятор для сигнала захваченного по спаду
    --==========================================================================  
    sync_phase_demod_l:entity work.sync_phase_demodulator
    port map
    (
        aclr      => aclr,
        clk420    => clk_420MHz,
        -- Вход модулированного сигнала
        sync_dat  => s_ddrsync_l,
        fmsg_stb  => s_carr_f,
        smsg_stb  => s_carr_s,
        -- битовый поток данных
        fmsg_ph1  => s_fmsg_ph(2),
        fmsg_ph2  => s_fmsg_ph(3),

        smsg_ph11 => s_smsg_ph(4),
        smsg_ph12 => s_smsg_ph(5),
        smsg_ph21 => s_smsg_ph(6),
        smsg_ph22 => s_smsg_ph(7)
    );
    
    s_fmsg_stb(0) <= s_carr_f;
    s_fmsg_stb(1) <= not s_carr_f;
    s_fmsg_stb(2) <= s_carr_f;
    s_fmsg_stb(3) <= not s_carr_f;
    
    matched_filters : for i in 0 to C_CHAN_NUM-1 generate
        bit_mf: entity work.bit_matched_filter
        generic map(
            PATTERN   => C_SYNCHRO_MSG,
            RES_WIDTH => C_BITMF_RES_WIDTH,
            SUMM_ENA  => false
        )
        port map(
            aclr => aclr,
            clk  => clk_420MHz,

            -- Вход модулированного сигнала
            idat => s_fmsg_ph(i),
            istb => s_fmsg_stb(i),

            --res  => s_bitmf_res(i)
            res_max => s_trh_obt(i)
        );
    end generate;
    
    
    --==========================================================================
    -- data delay line
    --==========================================================================
    s_fastmux_adr <= std_logic_vector(to_unsigned(s_path, 2));
    process(clk_420MHz)
    begin
        if(rising_edge(clk_420MHz)) then
            if( s_fastmux_adr(1) = '0' )then
                s_fastmux_st1 <= s_smsg_ph(3 downto 0);
            else
                s_fastmux_st1 <= s_smsg_ph(7 downto 4);
            end if;
            
            if( s_fastmux_adr(0) = '0' )then
                s_fastmux_st2 <= s_fastmux_st1(1 downto 0);
            else
                s_fastmux_st2 <= s_fastmux_st1(3 downto 2);
            end if;
            
            s_fastmux_dl(0) <= s_fastmux_st2;
            s_fastmux_dl(4 downto 1) <=  s_fastmux_dl(3 downto 0);
            
            if( s_sync_str = '1' )then
                s_fastmux_sw <= not s_carr_s;
            end if;

            if(s_fastmux_sw = '1')then
                s_datmsg_mux <= s_fastmux_dl(3)(0);
                s_errmsg_mux <= s_fastmux_dl(3)(1);
            else
                s_datmsg_mux <= s_fastmux_dl(3)(1);
                s_errmsg_mux <= s_fastmux_dl(3)(0);
            end if;
            
            if( s_slow_stb(1) = '1')then
                s_datmsg_slow <= s_datmsg_mux;
                --s_datmsg_slow <= s_datmsg_mux and not s_err_blank;
                s_strmsg_slow <= s_sync_str_vbr;
                s_errmsg_slow <= s_errmsg_mux;
            end if;
            
            -- if( s_err_blank = '0' and s_errmsg_mux = '1' )then
                -- s_err_blank <= '1';
            -- elsif( s_sync_str = '1')then
                -- s_err_blank <= '0';
            -- end if;
        end if;
    end process;  
    
    
    --==========================================================================
    -- data delay line
    --==========================================================================
    process(clk_420MHz, aclr)
    begin
        if(aclr = '1')then
            s_slow_stb <= (others => '0');
            s_sync_str <= '0';
            s_sync_str_vbr <= '0';
        elsif(rising_edge(clk_420MHz)) then
            if( s_sync_str = '1' )then
                s_slow_stb <= b"0001";
            else
                s_slow_stb(3 downto 1) <= s_slow_stb(2 downto 0);
                s_slow_stb(0) <= s_slow_stb(3);
            end if;
            
            s_sync_str <= s_trh_obt(s_path);
            if(s_sync_str = '1')then
                s_sync_str_vbr <= '1';
            elsif( s_slow_stb(3) = '1' )then
                s_sync_str_vbr <= '0';
            end if;
            -- if( s_trh_obt(s_path) = '1' )then
                -- s_sync_str <= '1';
            -- elsif( s_slow_stb(3) = '1' )then
                -- s_sync_str <= '0';
            -- end if;
            
        end if;
    end process;  
    
    
    --==========================================================================
    -- strob generator
    --==========================================================================
    process(clk_420MHz, aclr)
    begin
        if(aclr = '1')then
            s_trh_vbr <= (others => (others => '0'));
        elsif(rising_edge(clk_420MHz)) then
            
            for i in 0 to 3 loop
                if( s_trh_obt(i) = '1')then
                    s_trh_vbr(i) <= (others => '1');
                else
                    s_trh_vbr(i)(0) <= '0';
                    s_trh_vbr(i)(5 downto 1) <= s_trh_vbr(i)(4 downto 0);
                end if;
            end loop;
        end if;
    end process;  
    
    
    -- --==========================================================================
    -- -- strob generator
    -- --==========================================================================
    -- process(clk_420MHz, aclr)
    -- begin
        -- if(aclr = '1')then
            -- s_trh_obt <= (others => '0');
            -- s_bitmf_res_latch <= (others => (others => '0'));
        -- elsif(rising_edge(clk_420MHz)) then
            -- for i in 0 to 3 loop
                -- if(signed(s_bitmf_res(i)) > 22)then
                -- -- if(signed(s_bitmf_res(i)) > 22 and s_fmsg_stb(i) = '0')then
                    -- s_bitmf_res_latch(i) <= s_bitmf_res(i);
                    -- s_trh_obt(i) <= '1';
                -- else
                    -- s_trh_obt(i) <= '0';
                -- end if;
            -- end loop;
        -- end if;
    -- end process;  
    
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_trh_obt_s <= (others => '0');
            s_trh_obt_s_r <= (others => '0');
        elsif(rising_edge(clk_105MHz)) then
            
            for i in 0 to 3 loop
                if( s_trh_vbr(i)(5) = '1' )then
                    s_trh_obt_s(i) <= not s_trh_obt_s(i);
                else
                    s_trh_obt_s(i) <= '0';
                end if;
            end loop;
            s_trh_obt_s_r <= s_trh_obt_s;
        end if;
    end process;  
    
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_trh_cnt <= (others => (others => '0'));
            s_trh_chek <= '0';
        elsif(rising_edge(clk_105MHz)) then
            s_trh_chek <= or_bus(s_trh_obt_s) and not or_bus(s_trh_obt_s_r);
            
            for i in 0 to 3 loop
                if(s_trh_chek = '1')then
                    if( (s_trh_obt_s_r(i) or s_trh_obt_s(i)) = '1' ) then
                        if( s_trh_cnt(i) /= x"F" )then
                            s_trh_cnt(i) <= s_trh_cnt(i) + 1;
                        end if;
                    else
                        if( s_trh_cnt(i) /= x"0" )then
                            s_trh_cnt(i) <= s_trh_cnt(i) - 1;
                        end if;
                    end if;
                end if;
            end loop;
        end if;
    end process;  
    
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_max_path <= 0;
            s_path <= 0;
        elsif(rising_edge(clk_105MHz)) then
        
            if( s_trh_cnt(0) > s_trh_cnt(1) )then
                if( s_trh_cnt(0) > s_trh_cnt(2) )then
                    if( s_trh_cnt(0) > s_trh_cnt(3) )then
                        s_max_path <= 0;
                    else
                        s_max_path <= 3;
                    end if;
                elsif( s_trh_cnt(2) > s_trh_cnt(3))then
                    s_max_path <= 2;
                else
                    s_max_path <= 3;
                end if;
            elsif( s_trh_cnt(1) > s_trh_cnt(2))then
                if( s_trh_cnt(1) > s_trh_cnt(3))then
                    s_max_path <= 1;
                else
                    s_max_path <= 3;
                end if;
            else
                s_max_path <= 2;
            end if;
            
            if( or_bus(s_trh_good and not(s_trh_good_fail)) = '1' )then
                if((s_trh_good(0) and not s_trh_good_fail(0)) = '1')then
                    s_path <= 0;
                elsif((s_trh_good(1) and not s_trh_good_fail(1)) = '1')then
                    s_path <= 1;
                elsif((s_trh_good(2) and not s_trh_good_fail(2)) = '1')then
                    s_path <= 2;
                elsif((s_trh_good(3) and not s_trh_good_fail(3)) = '1')then
                    s_path <= 3;
                end if;
            else
                s_path <= s_max_path;
            end if;
        end if;
    end process;  
    
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_trh_good <= (others => '0');
            s_trh_good_fail <= (others => '0');
        elsif(rising_edge(clk_105MHz)) then
            
            for i in 0 to 3 loop
                if( s_trh_cnt(i) = x"F" )then
                    s_trh_good(i) <= '1';
                else
                    s_trh_good(i) <= '0';
                end if;
                
                if( (s_trh_good(i) = '1') and (s_trh_cnt(i) /= x"F") )then
                    s_trh_good_fail(i) <= '1';
                elsif( trh_rst = '1' )then
                    s_trh_good_fail(i) <= '0';
                end if;
                
            end loop;
        end if;
    end process;  
    
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_cdc_dat  <= '0';
            s_cdc_err  <= '0';
            s_cdc_sstr <= '0';
        elsif(rising_edge(clk_105MHz)) then
            s_cdc_dat  <= s_datmsg_slow;
            s_cdc_err  <= s_errmsg_slow;
            s_cdc_sstr <= s_strmsg_slow;
        end if;
    end process;  
    
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_qcnt     <= (others => '0');
            --
            s_ser_dat  <= (others => '0');
            s_ser_err  <= '0';
            s_ser_sync <= '0';
            s_ser_time <= '0';
            s_ser_qstr <= '0';
            s_ser_qend <= '0';
            s_ser_stb  <= '0';
            --
        elsif(rising_edge(clk_105MHz)) then
            s_ser_dat(15) <= s_cdc_dat;
            s_ser_dat(14 downto 0) <= s_ser_dat(15 downto 1);
            
            if( s_cdc_sstr = '1' or s_qcnt = x"00" )then
                s_qcnt <= x"7F";
            else
                s_qcnt <= s_qcnt - 1;
            end if;
            
            if( s_cdc_sstr = '0' and s_qcnt(3 downto 0) = x"1" )then s_ser_stb <= '1';
            else s_ser_stb <= '0'; end if;
            
            if( s_qcnt = x"01" )then s_ser_qstr <= '1';
            else s_ser_qstr <= '0'; end if;
            
            if( s_qcnt = x"11" )then s_ser_qend <= '1';
            else s_ser_qend <= '0'; end if;
            
            if( s_cdc_sstr = '1' )then s_ser_time <= '1';
            elsif( s_qcnt = x"51" )then s_ser_time <= '0';
            end if;
            
            if( s_cdc_sstr = '1' )then s_ser_sync <= '1';
            elsif( s_qcnt = x"50" )then s_ser_sync <= '0';
            end if;
            
        end if;
    end process;  
    
    --=============================================
    -- Рассчет CRC
    --=============================================
    crc: entity work.crc16_iw16
    generic map(
        INIT      => x"FFFF",
        IBIT_REV  => false,
        IBYTE_REV => true
    )
    port map(
        clk     => clk_105MHz,
        rst     => s_cdc_sstr,
        ena     => s_ser_stb,
        input   => s_ser_dat,
        output  => s_crc_dat
    );
    
    --==========================================================================
    -- clock domain crossing
    --==========================================================================
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_time_rec  <= (others => '0');
            s_time_stb  <= '0';
            --
        elsif(rising_edge(clk_105MHz)) then
            if( s_ser_stb = '1' and s_ser_time = '1' )then
                s_time_rec(31 downto 16) <= s_ser_dat;
                s_time_rec(15 downto 0)  <= s_time_rec(31 downto 16);
            end if;
            
            if( s_crc_dat = s_ser_dat ) then
                s_time_stb <= s_ser_stb and s_ser_sync;
            else
                s_time_stb <= '0';
            end if;
            
        end if;
    end process;   
    
    
    --==========================================================================
    -- Назначение выходных сигналов
    --==========================================================================
    synch_ok   <= or_bus(s_trh_good);
    time_dat   <= s_time_rec;
    time_stb   <= s_time_stb;
  
    sync_dat   <= s_ser_dat;
    sync_stb   <= s_ser_stb;
    sync_qstr  <= s_ser_qstr;
    sync_qend  <= s_ser_qend;
    
end impl;