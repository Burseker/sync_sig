--================================================================================
-- Description: strobe path cross domain crossing
-- Version:     0.1.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    DMA
-- Tools:       modelsim 10.2d
--              
-- Note:
-- 
-- Version History:
-- Ver 0.0.0 - File create
-- Ver 0.1.0 - Рабочая версия.
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stb_cdc_v2 is
    generic (
        OREG    : boolean := false
        -- ACK_FEEDBACK_ENA    : boolean := false
    );
    port (
        aclr    : in  std_logic;
        iclk    : in  std_logic;
        oclk    : in  std_logic;
        
        istb    : in  std_logic := '0';
        ostb    : out std_logic := '0'
    );
end stb_cdc_v2;

architecture beh of stb_cdc_v2 is

    --=========================================
    -- type t_ctrl_stm is (ST_IDLE, ST_UPLOAD, ST_TRASH, ST_WAIT_DMARDY);
    -- signal s_ctrl_stm   : t_ctrl_stm := ST_IDLE;
    
    --=========================================
    -- iclk signals
    --=========================================
    signal s_istb_r     : std_logic := '0';
    signal w_istb_ld    : std_logic := '0';
    signal s_icd_ena    : std_logic := '0';
    
    --=========================================
    -- oclk signals
    --=========================================
    signal s_ocd_stb    : std_logic := '0';
    
    --load data pulse gen
    signal s_oldpg0     : std_logic := '0';
    signal s_oldpg1     : std_logic := '0';
    signal s_oldpg2     : std_logic := '0';
    signal w_oldpg      : std_logic := '0';
    
begin
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    -- process(aclr, iclk)
    -- begin
        -- if(aclr = '1')then
        -- elsif(rising_edge(iclk))then
        -- end if;
    -- end process;
    
    
--===========================================================
--===========================================================
--===========================================================
--===========================================================
--===========================================================
-- INPUT CLOCK DOMAIN PROCESSES
--===========================================================
--===========================================================
--===========================================================
--===========================================================
--===========================================================
--=============================================
-- INPUT ENA STATE MASHINE
--=============================================
    process(aclr, iclk)
    begin
        if(aclr = '1')then
            s_istb_r <= '0';
        elsif(rising_edge(iclk))then
            s_istb_r <= istb;
        end if;
    end process;
    w_istb_ld <= istb and not s_istb_r;
    
--=============================================
-- REGISTER AND TOGGLE ON FRINGE
--=============================================
    process(aclr, iclk)
    begin
        if(aclr = '1')then
            s_icd_ena <= '0';
        elsif(rising_edge(iclk))then
            s_icd_ena <= w_istb_ld xor s_icd_ena;
        end if;
    end process;
    
--===========================================================
--===========================================================
--===========================================================
--===========================================================
--===========================================================
-- OUTPUT CLOCK DOMAIN PROCESSES
--===========================================================
--===========================================================
--===========================================================
--===========================================================
--===========================================================
--=============================================
-- LOAD DATA PULSE GEN
--=============================================
    process(aclr, oclk)
    begin
        if(aclr = '1')then
            s_oldpg0 <= '0';
            s_oldpg1 <= '0';
            s_oldpg2 <= '0';
        elsif(rising_edge(oclk))then
            s_oldpg0 <= s_icd_ena;
            s_oldpg1 <= s_oldpg0;
            s_oldpg2 <= s_oldpg1;
        end if;
    end process;
    w_oldpg <= s_oldpg1 xor s_oldpg2;
    
    
no_oreg_gen: if (OREG = false) generate
    s_ocd_stb <= w_oldpg;
end generate no_oreg_gen;


oreg_gen: if (OREG = true) generate
    --=============================================
    -- TYPICAL PROCESS
    --=============================================
        process(aclr, oclk)
        begin
            if(aclr = '1')then
                s_ocd_stb <= '0';
            elsif(rising_edge(oclk))then
                s_ocd_stb <= w_oldpg;
            end if;
        end process;
end generate oreg_gen;
    
    
--=============================================
-- OUTPUT SIGNALS ASSIGMENT
--=============================================
    ostb <= s_ocd_stb;
    
end beh;
