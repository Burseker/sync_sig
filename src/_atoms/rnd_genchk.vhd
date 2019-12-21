--================================================================================
-- Description: Имитация и проверка рандомной последовательности.
-- Version:     0.1.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
--
-- Keywords:    generator checker
-- Tools:       Altera Quartus 9.1 SP1
--            
-- Details:
--          
-- Version History:   
-- Ver 0.0.0 - Черновой вариант
-- Ver 0.1.0 - Рабочий вариант. Последовательность циклична.
--
--
--
-- Additional Comments:         
-- 
-- PIPLINE OF MODULE IS 1
-- 
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- use work.qpkt_pkg.all;
-- use work.pkg_func.all;

entity rnd_genchk is
    generic(
        WIDTH   : natural := 32;
        C_INIT  : natural := 16#233A#;
        HPOS    : natural := 17;
        LPOS    : natural := 22
    );
    port( 
        aclr    : in  std_logic;
        clk     : in  std_logic;
        init    : in  std_logic_vector(WIDTH-1 downto 0);
        
        ichk    : in  std_logic;
        idat    : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
        istb    : in  std_logic;
        istr    : in  std_logic;
        
        odat    : out std_logic_vector(WIDTH-1 downto 0);
        ostb    : out std_logic;
        ostr    : out std_logic;
        
        rnd_ok  : out std_logic
    );
end rnd_genchk;

architecture beh of rnd_genchk is

    -- signal s_chk_cnt    : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal s_ini_rnd    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_wrk_rnd    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_new_rnd    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    
    signal s_odat       : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_ostr       : std_logic := '0';
    signal s_ostb       : std_logic := '0';
    
    signal s_rnd_ok     : std_logic := '0';
    
begin

    s_ini_rnd <= init(WIDTH-2 downto 0) & (init(HPOS) xor init(LPOS));
    s_new_rnd <= idat(WIDTH-2 downto 0) & (idat(HPOS) xor idat(LPOS));
    s_wrk_rnd <= s_odat(WIDTH-2 downto 0) & (s_odat(HPOS) xor s_odat(LPOS));
--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_odat <= std_logic_vector(to_unsigned(C_INIT, WIDTH));
        elsif(rising_edge(clk))then
            if( istb = '1' )then
                if( istr = '1' )then
                    s_odat <= s_ini_rnd;
                else
                    if( ichk = '1' )then
                        s_odat <= idat;
                    else
                        s_odat <= s_wrk_rnd;
                    end if;
                end if;
            elsif( istr = '1' )then
                s_odat <= init;
            end if;
            
        end if;
    end process;
    
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_rnd_ok <= '0';
        elsif(rising_edge(clk))then
            if( istb = '1' )then
                if( s_ini_rnd = idat and istr = '1')then s_rnd_ok <= '1';
                elsif( s_wrk_rnd = idat and istr = '0')then s_rnd_ok <= '1';
                else s_rnd_ok <= '0'; end if;
            elsif( istr = '1' )then
                s_rnd_ok <= '1';
            end if;
        end if;
    end process;
    
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_ostr <= '0';
            s_ostb <= '0';
        elsif(rising_edge(clk))then
            s_ostb <= istb;
            if( istb = '1' )then
                s_ostr <= istr;
            end if;
        end if;
    end process;
    
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    odat    <= s_odat;
    ostb    <= s_ostb;
    ostr    <= s_ostr;
    
    rnd_ok  <= s_rnd_ok;
    
end beh;

