--==============================================================================
-- Description: Блок перехода тактовых асинхронных доменов для обнобитного
--              сигнала.
-- Version:     0.0.0
-- Developer:   SVB
-- Workgroup:   IRS16
--==============================================================================
-- Keywords:    sync_dc_shiftreg
-- Tools:       Altera Quartus 9.1 SP1
--              
-- Details:     Блок не доделан. Может быть использован в схемах где нет
--              возможности осуществлять обработку на 420 МГц. Так же в блоке 
--              работает сборщик данных для сигналтапа. Выдается входная после-
--              довательность, перенесанная с 420 на 105.
-- 
-- Version History:
-- Ver 0.0.0 - File created
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
-- USE altera_mf.all;
--=========================

entity sync_dc_shiftreg is
port
(
  clk_420MHz : in std_logic;
  clk_105MHz : in std_logic;
  aclr       : in std_logic;
  
  sync       : in std_logic;
  prns_str   : in std_logic;
  
  sync_dat   : out std_logic_vector(7 downto 0);
  sync_stb   : out std_logic
);
end sync_dc_shiftreg;

architecture beh of sync_dc_shiftreg is

    signal s_sync_r       : std_logic := '0';
    
    signal s_wrptr        : std_logic_vector(7 downto 0) := (others => '0');
    signal s_shreg_sel    : std_logic := '0';
    signal s_rd_stb       : std_logic := '0';
    signal s_fast_shrg_0  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_fast_shrg_1  : std_logic_vector(7 downto 0) := (others => '0');
    
    signal s_slow_dat     : std_logic_vector(7 downto 0) := (others => '0');
    signal s_slow_dat_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal s_slow_stb     : std_logic := '0';
    signal s_slow_stb_r   : std_logic := '0';
    
    type t_ctrl_stm is (IDLE, MEM_READ);
    signal s_ctrl_stm       : t_ctrl_stm := IDLE;
    signal s_del_ena        : std_logic := '0';
    signal s_del_wr         : std_logic := '0';
    signal s_del_rd         : std_logic := '0';
    
    signal s_del_odat       : std_logic_vector(7 downto 0) := (others => '0');
    signal s_del_rdcnt      : unsigned(8 downto 0) := (others => '0');
    signal s_out_shreg      : std_logic_vector(7 downto 0) := (others => '0');
    
    -- DEBUG SIGNALS
    attribute noprune: boolean;
    signal s_ser_data    : std_logic := '0';
    signal s_ser_data_r  : std_logic := '0';
    signal s_ser_data_rr : std_logic := '0';
    attribute noprune of s_ser_data_rr : signal is true;
    
begin 
    --==========================================================================
    -- Входной регистр
    --==========================================================================
    process(clk_420MHz, aclr)
    begin
        if (aclr = '1') then
            s_sync_r    <= '0';
        elsif(rising_edge(clk_420MHz)) then
            s_sync_r    <= sync;
        end if;
    end process;    
    
    
    
    --==========================================================================
    -- strob generator
    --==========================================================================
    process(clk_420MHz, aclr)
    begin
        if (aclr = '1') then
            s_wrptr     <= x"01";
            s_shreg_sel <= '0';
        elsif(rising_edge(clk_420MHz)) then
            s_wrptr(0) <= s_wrptr(7);
            s_wrptr(7 downto 1) <= s_wrptr(6 downto 0);
            
            if( s_wrptr(7) = '1' )then
                s_shreg_sel <= not s_shreg_sel;
            end if;
            
            if( s_wrptr(1) = '1' )then
                s_rd_stb <= '1';
            elsif( s_wrptr(5) = '1' )then
                s_rd_stb <= '0';
            end if;
        end if;
    end process;  
    
    
    --==========================================================================
    -- double buffer
    --==========================================================================
    process(clk_420MHz, aclr)
    begin
        if (aclr = '1') then
            s_fast_shrg_0  <= (others => '0');
            s_fast_shrg_1  <= (others => '0');
        elsif(rising_edge(clk_420MHz)) then
            if( s_shreg_sel = '0' )then
                s_fast_shrg_0(0) <= s_sync_r;
                s_fast_shrg_0(7 downto 1) <= s_fast_shrg_0(6 downto 0);
            else
                s_fast_shrg_1(0) <= s_sync_r;
                s_fast_shrg_1(7 downto 1) <= s_fast_shrg_1(6 downto 0);
            end if;
            
        end if;
    end process;  
    
    
    --==========================================================================
    -- concatination
    --==========================================================================   
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_slow_dat      <= (others => '0');
            s_slow_stb      <= '0';
            s_slow_dat_r    <= (others => '0');
            s_slow_stb_r    <= '0';
        elsif(rising_edge(clk_105MHz)) then
            if( s_rd_stb = '1' ) then
                if( s_shreg_sel = '0' ) then
                    s_slow_dat <= s_fast_shrg_1;
                else
                    s_slow_dat <= s_fast_shrg_0;
                end if;
            end if;
            s_slow_dat_r <= s_slow_dat;
            
            s_slow_stb   <= s_rd_stb;
            s_slow_stb_r <= s_slow_stb;
        end if;
    end process;    
    
    
    --==========================================================================
    -- delay line
    --==========================================================================   
    del_line : entity work.del_line_v21
	generic map(
		iwidth => 8,
		depth  => 64,
		base   => "RAM",--"REG", "RAM", "LUT"
		style  => "Auto")--"Auto", "M512", "M4K", "M-RAM", "MLAB", "M9K", "M144K", "logic"
	port map(
		aclr   => aclr,
		clk    => clk_105MHz,
		enable => s_del_ena,
		din    => s_slow_dat_r,
		dout   => s_del_odat
	);
    s_del_ena <= (s_del_wr and s_slow_stb_r) or s_del_rd;
    
    
    --==========================================================================
    -- read from delay statemashine
    --==========================================================================   
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_ctrl_stm  <= IDLE;
            s_del_wr    <= '0';
            s_del_rd    <= '0';
            s_del_rdcnt <= (others => '0');
        elsif(rising_edge(clk_105MHz)) then
            case s_ctrl_stm is
                when IDLE =>
                    if( prns_str = '1' )then
                        s_ctrl_stm  <= MEM_READ;
                        s_del_wr    <= '0';
                    else
                        s_del_wr    <= '1';
                    end if;
                    s_del_rd    <= '0';
                    -- s_del_rdcnt <= (others => '0');
                when MEM_READ =>
                    if( s_del_rdcnt = (s_del_rdcnt'range => '1') ) then
                        s_del_rdcnt <= (others => '0');
                        s_ctrl_stm  <= IDLE;
                    else
                        s_del_rdcnt <= s_del_rdcnt + 1;
                    end if;
                    
                    if( s_del_rdcnt(2 downto 0) = b"000" ) then
                        s_del_rd    <= '1';
                    else
                        s_del_rd    <= '0';
                    end if;
            end case;
        end if;
    end process; 
    
    
    --==========================================================================
    -- serializer shift registr
    --==========================================================================   
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_out_shreg <= (others => '0');
        elsif(rising_edge(clk_105MHz)) then
            if( s_del_rd = '1' )then
                s_out_shreg <= s_del_odat;
            else
                s_out_shreg(7 downto 1) <= s_out_shreg(6 downto 0);
            end if;
            s_ser_data <= s_out_shreg(7);
        end if;
    end process;   
    
    
    --==========================================================================
    -- out register
    --==========================================================================   
    process(clk_105MHz, aclr)
    begin
        if (aclr = '1') then
            s_ser_data_r <= '0';
            s_ser_data_rr <= '0';
        elsif(rising_edge(clk_105MHz)) then
            s_ser_data_r <= s_ser_data;
            s_ser_data_rr <= s_ser_data_r;
        end if;
    end process;    
    
    
    --==========================================================================
    -- Назначение выходных сигналов
    --==========================================================================
    sync_dat   <= s_slow_dat_r;
    sync_stb   <= s_slow_stb_r;
  
end beh;