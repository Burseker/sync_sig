--================================================================================
-- Description: Модуль тестирования последовательности ZERO-ONE
-- Version:     0.0.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    ADC
-- Tools:       modelsim 10.2d
--              
-- Note:
-- 
-- Version History:
-- Ver 0.0.0 - File create
--
--
----------------------------------------------------------------------------------

--=== basic lib ===
library ieee;                                               
use ieee.std_logic_1164.all;

--=== std logic lib ===
-- USE IEEE.STD_LOGIC_ARITH.ALL;
-- USE IEEE.STD_LOGIC_UNSIGNED.ALL;

--=== numeric std lib ===
use ieee.numeric_std.all;

--=== common lib ===
-- use work.xqpkt_pkg.all;
-- use work.qpkt_pkg.all;
-- use work.pkg_func.all;
-- use work.qpkt_imit_pkg.all;

entity zero_one_check is
    generic (
        -- SIM     : integer := 0
        WIDTH       : integer := 16
    );
    port (
        aclr        : in  std_logic;
        clk         : in  std_logic;
        
        idat        : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
        istb        : in  std_logic := '0';
        
        chk_ok      : out std_logic
    );
end zero_one_check;

architecture beh of zero_one_check is

    -- --=========================================
    -- type t_rx_stm is (ST_IDLE, ST_RXPKT);
    -- signal s_rx_stm   : t_rx_stm := ST_IDLE;
    --=========================================
    signal s_reg    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_cnt    : unsigned(1 downto 0) := (others => '0');
    signal s_chk_ok : std_logic := '0';
    --=========================================
    
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
            s_reg    <= (others => '0');
            s_cnt    <= (others => '0');
            s_chk_ok <= '0';
        elsif(rising_edge(clk))then
            if(istb = '1')then
                if(s_reg = idat)then
                    s_reg <= not s_reg;
                    if(s_cnt < 3)then
                        s_cnt <= s_cnt + 1;
                    end if;
                else
                    s_reg <= (others => '0');
                    s_cnt <= (others => '0');
                end if;
            end if;
            
            if(s_cnt = 3)then
                s_chk_ok <= '1';
            else
                s_chk_ok <= '0';
            end if;
        end if;
    end process;
    
    
--=============================================
-- НАЗНАЧЕНИЕ ВЫХОДНЫХ СИГНАЛОВ
--=============================================
    chk_ok <= s_chk_ok;

end beh;
