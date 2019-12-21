--================================================================================
-- Description: Имитатор пакетного потока.
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
-- Ver 0.1.0 - Рабочий вариант
--
--
-- Additional Comments:         
-- 
-- 
-- 
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.pkg_link.all;
-- use work.pkg_func.all;

entity cnt_genchk is
    generic(
        WIDTH      : natural := 32
    );
    port( 
        aclr    : in  std_logic;
        clk     : in  std_logic;
        
        ichk    : in  std_logic;
        idat    : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
        istb    : in  std_logic;
        istr    : in  std_logic;
        
        odat    : out std_logic_vector(WIDTH-1 downto 0);
        ostb    : out std_logic;
        ostr    : out std_logic;
        
        cnt_ok  : out std_logic
    );
end cnt_genchk;

architecture beh of cnt_genchk is

    -- signal s_chk_cnt    : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal s_wrk_cnt    : unsigned(WIDTH-1 downto 0) := (others => '0');
    
    signal s_odat       : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_ostr       : std_logic := '0';
    signal s_ostb       : std_logic := '0';
    
    signal s_cnt_ok     : std_logic := '0';
    
begin


--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_wrk_cnt <= (others => '0');
        elsif(rising_edge(clk))then
            if( istb = '1' )then
                if( ichk = '1' )then
                    s_wrk_cnt <= unsigned(idat);
                elsif( istr = '1' or s_wrk_cnt = (s_wrk_cnt'range => '1'))then
                    s_wrk_cnt <= (others => '0');
                else
                    s_wrk_cnt <= s_wrk_cnt + 1;
                end if;
            elsif( istr = '1' )then
                s_wrk_cnt <= (others => '1');
            end if;
            
        end if;
    end process;
    
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, clk)
    begin
        if(aclr = '1')then
            s_cnt_ok <= '0';
        elsif(rising_edge(clk))then
            if( istb = '1' )then
                if( idat = (idat'range => '0') and istr = '1' )then s_cnt_ok <= '1';
                elsif( idat = std_logic_vector(s_wrk_cnt + 1) and istr = '0' )then s_cnt_ok <= '1';
                else s_cnt_ok <= '0'; end if;
            elsif( istr = '1' )then
                s_cnt_ok <= '1';
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
    odat    <= std_logic_vector(s_wrk_cnt);
    ostb    <= s_ostb;
    ostr    <= s_ostr;
    
    cnt_ok  <= s_cnt_ok;
    
end beh;

