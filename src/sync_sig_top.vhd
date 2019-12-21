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


    -- service signals
    signal s_rtime          : unsigned(31 downto 0) := (others => '0');
    signal s_rtime_aux      : unsigned(31 downto 0) := (others => '0');
    
    signal s_adcimit_dat    : std_logic_vector(15 downto 0) := (others => '0');
    signal s_adcimit_or     : std_logic := '0';
    signal s_latch_rst      : std_logic := '0';
    signal s_new_dist       : std_logic := '0';
    
    
    -- -- chanel signals
    -- type T_ADC_RAW is record
        -- p_dat     : std_logic_vector(31 downto 0);
        -- p_end     : std_logic;
        -- p_stb     : std_logic;
        -- p_ten     : std_logic;
        
        -- w512_addr : std_logic_vector(23 downto 0);
        -- w512_size : std_logic_vector(23 downto 0);
        -- w512_stb  : std_logic;
        -- w512_rdy  : std_logic;
    -- end record;
    -- type T_ADC_RAW_ARR4 is array (0 to 7) of T_ADC_RAW;
    
    -- signal s_adc_prc : T_ADC_RAW_ARR4 := (others => ((others => '0'), '0', '0', '0',
                                                    -- (others => '0'), (others => '0'), '0', '0'
                                                   -- )
                                        -- );
    
    -- signal s_adchdr_prc : T_ADC_RAW := ((others => '0'), '0', '0', '0',
                                        -- (others => '0'), (others => '0'), '0', '0'
                                        -- );
    
    
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
    --s_adcimit_dat <= std_logic_vector(s_rtime(15 downto 0));
    --s_adcimit_dat <= x"0100" when s_rtime(15 downto 0) = x"04C3" else x"0000";
    
    s_latch_rst   <= '1' when s_rtime_aux(15 downto 0) = x"34C3" else '0';
    s_new_dist    <= '1' when s_rtime(15 downto 0) = x"0E80" else '0';
    
    
--=============================================
-- OUTPUT ASSIGMENTS
--=============================================
    
end beh;
