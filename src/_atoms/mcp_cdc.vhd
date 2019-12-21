--================================================================================
-- Description: Multi-Cycle Path cross domain crossing
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

entity mcp_cdc is
    generic (
        SIM                 : integer := 0;
        WIDTH               : natural := 8;
        ACK_FEEDBACK_ENA    : boolean := false
    );
    port (
        aclr    : in  std_logic;
        iclk    : in  std_logic;
        oclk    : in  std_logic;
        
        idat    : in  std_logic_vector(WIDTH-1 downto 0) := (others => '0');
        istb    : in  std_logic := '0';
        irdy    : out std_logic := '0';
        
        odat    : out std_logic_vector(WIDTH-1 downto 0) := (others => '0');
        ostb    : out std_logic := '0';
        ovld    : out std_logic := '0';
        oload   : in  std_logic := '0'
    );
end mcp_cdc;

architecture beh of mcp_cdc is

    --=========================================
    -- type t_ctrl_stm is (ST_IDLE, ST_UPLOAD, ST_TRASH, ST_WAIT_DMARDY);
    -- signal s_ctrl_stm   : t_ctrl_stm := ST_IDLE;
    
    --=========================================
    -- iclk signals
    --=========================================
    signal s_istm       : std_logic := '0';
    signal s_icd_reg    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_icd_ena    : std_logic := '0';
    
    --load data pulse gen
    signal s_ildpg0     : std_logic := '0';
    signal s_ildpg1     : std_logic := '0';
    signal s_ildpg2     : std_logic := '0';
    signal w_ildpg      : std_logic := '0';
    
    --=========================================
    -- oclk signals
    --=========================================
    signal s_ocd_ack    : std_logic := '0';
    signal s_ostm       : std_logic := '0';
    signal s_ocd_reg    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal s_ocd_load   : std_logic := '0';
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
            s_istm <= '0';
        elsif(rising_edge(iclk))then
            if( s_istm = '0' )then
                s_istm <= istb;
            else
                s_istm <= not w_ildpg;
            end if;
        end if;
    end process;

    
--=============================================
-- LOAD DATA PULSE GEN
--=============================================
    process(aclr, iclk)
    begin
        if(aclr = '1')then
            s_ildpg0 <= '0';
            s_ildpg1 <= '0';
            s_ildpg2 <= '0';
        elsif(rising_edge(iclk))then
            s_ildpg0 <= s_ocd_ack;
            s_ildpg1 <= s_ildpg0;
            s_ildpg2 <= s_ildpg1;
        end if;
    end process;
    w_ildpg <= s_ildpg1 xor s_ildpg2;
    
    
--=============================================
-- REGISTER AND TOGGLE ON FRINGE
--=============================================
    process(aclr, iclk)
    begin
        if(aclr = '1')then
            s_icd_reg <= (others => '0');
            s_icd_ena <= '0';
        elsif(rising_edge(iclk))then
            if( s_istm = '0' and istb = '1' )then
                s_icd_reg <= idat;
            end if;
            s_icd_ena <= (not s_istm and istb) xor s_icd_ena;
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
    

--=============================================
-- LATCH FOR DATA BUS
--=============================================

    process(aclr, oclk)
    begin
        if(aclr = '1')then
            s_ocd_reg <= (others => '0');
        elsif(rising_edge(oclk))then
            if( s_ocd_load = '1' )then
                s_ocd_reg <= s_icd_reg;
            end if;
        end if;
    end process;
        
--=============================================
-- TYPICAL PROCESS
--=============================================
    process(aclr, oclk)
    begin
        if(aclr = '1')then
            s_ocd_ack <= '0';
        elsif(rising_edge(oclk))then
            s_ocd_ack <= s_ocd_ack xor s_ocd_load;
        end if;
    end process;
    
    
no_acknowledge_feedback_gen: if (ACK_FEEDBACK_ENA = false) generate
    
        s_ocd_load <= w_oldpg;
    
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
end generate no_acknowledge_feedback_gen;


acknowledge_feedback_gen: if (ACK_FEEDBACK_ENA = true) generate
    
    --=============================================
    -- TYPICAL PROCESS
    --=============================================
        process(aclr, oclk)
        begin
            if(aclr = '1')then
                s_ostm <= '0';
            elsif(rising_edge(oclk))then
                if( s_ostm = '0' )then
                    s_ostm <= w_oldpg;
                else
                    s_ostm <= not oload;
                end if;
            end if;
        end process;
        
        s_ocd_load <= s_ostm and oload;
        
    --=============================================
    -- TYPICAL PROCESS
    --=============================================
        process(aclr, oclk)
        begin
            if(aclr = '1')then
                s_ocd_stb <= '0';
            elsif(rising_edge(oclk))then
                s_ocd_stb <= s_ocd_load;
            end if;
        end process;
end generate acknowledge_feedback_gen;
    
    
--=============================================
-- OUTPUT SIGNALS ASSIGMENT
--=============================================
    irdy <= not s_istm;
    odat <= s_ocd_reg;
    ostb <= s_ocd_stb;
    
    ovld <= s_ostm;
    
end beh;
