--================================================================================
-- Description: Фазовый демодулятор для выделения несущей сигналов SYNC
-- Version:     0.0.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    im_sync
-- Tools:       Altera Quartus 9.1 SP1
--              
-- Details: 
-- 
-- Version History:
-- Ver 0.0.0 - File created
--
-- 
----------------------------------------------------------------------------------
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

entity sync_phase_demodulator is
-- generic
-- (
    -- -- Начало передачи со старшего разряда
    -- MSB_FIRST : boolean := false
-- );
port
(
    aclr      : in  std_logic;
    clk420    : in  std_logic;
    --clk105    : in  std_logic;
    
    -- Вход модулированного сигнала
    sync_dat  : in  std_logic;
    fmsg_stb  : in  std_logic;
    smsg_stb  : in  std_logic;
    
    -- битовый поток данных
    fmsg_ph1  : out std_logic;
    fmsg_ph2  : out std_logic;
    
    smsg_ph11 : out std_logic;
    smsg_ph12 : out std_logic;
    smsg_ph21 : out std_logic;
    smsg_ph22 : out std_logic
);
end sync_phase_demodulator;


architecture beh of sync_phase_demodulator is
    
    -- работа с быстрой несущей
    signal s_xor_carr1: std_logic   := '0';
    signal s_xor_carr1_r: std_logic := '0';
    signal s_fmsg_ph1: std_logic    := '0';
    signal s_fmsg_ph2: std_logic    := '0';
    
    -- работа с медленной несущей
    signal s_carr2_1    : std_logic := '0';
    signal s_carr2_2    : std_logic := '0';
    signal s_carr2_1_r  : std_logic := '0';
    signal s_carr2_2_r  : std_logic := '0';
    signal s_xor_carr2_1: std_logic := '0';
    signal s_xor_carr2_2: std_logic := '0';
    signal s_xor_carr2_1_r: std_logic := '0';
    signal s_xor_carr2_1_rr: std_logic := '0';
    signal s_xor_carr2_2_r: std_logic := '0';
    signal s_xor_carr2_2_rr: std_logic := '0';
    
    signal s_smsg_ph1_1 : std_logic    := '0';
    signal s_smsg_ph1_2 : std_logic    := '0';
    signal s_smsg_ph2_1 : std_logic    := '0';
    signal s_smsg_ph2_2 : std_logic    := '0';
begin
    
    
    --==========================================================================
    -- синхронизация частот
    --==========================================================================
    -- process(clk420, aclr)
    -- begin
        -- if (aclr = '1') then
        -- elsif(rising_edge(clk420)) then
        -- end if;
    -- end process;
    
    --==========================================================================
    -- Процесс обработки быстрой несущей
    --==========================================================================
    process(clk420, aclr)
    begin
        if (aclr = '1') then
            s_xor_carr1   <= '0';
            s_xor_carr1_r <= '0';
            s_fmsg_ph1    <= '0';
            s_fmsg_ph2    <= '0';
            
        elsif(rising_edge(clk420)) then
            s_xor_carr1 <= sync_dat xor fmsg_stb;
            s_xor_carr1_r <= s_xor_carr1;
                
            if( fmsg_stb = '1')then
                s_fmsg_ph1 <= s_xor_carr1 xor s_xor_carr1_r;
            else   
                s_fmsg_ph2 <= s_xor_carr1 xor s_xor_carr1_r;
            end if;
        end if;
    end process;
    
    
    --==========================================================================
    -- формирование опоры для медленной несущей
    --==========================================================================
    process(clk420, aclr)
    begin
        if (aclr = '1') then
            s_carr2_1  <= '0';
            s_carr2_2  <= '0';
            
            s_carr2_1_r  <= '0';
            s_carr2_2_r  <= '0';
            
        elsif(rising_edge(clk420)) then
            s_carr2_1 <= smsg_stb;
            s_carr2_2 <= s_carr2_1;
            
            s_carr2_1_r  <= s_carr2_1;
            s_carr2_2_r  <= s_carr2_1_r;
        end if;
    end process;
    
    
    --==========================================================================
    -- Процесс обработки медленной несущей
    --==========================================================================
    process(clk420, aclr)
    begin
        if (aclr = '1') then
            s_xor_carr2_1 <= '0';
            s_xor_carr2_2 <= '0';
        elsif(rising_edge(clk420)) then
            s_xor_carr2_1 <= sync_dat xor s_carr2_1;
            s_xor_carr2_1_r <= s_xor_carr2_1;
            s_xor_carr2_1_rr <= s_xor_carr2_1_r;
            if( s_carr2_1_r = '1')then
                s_smsg_ph1_1 <= s_xor_carr2_1 xor s_xor_carr2_1_rr;
            else   
                s_smsg_ph1_2 <= s_xor_carr2_1 xor s_xor_carr2_1_rr;
            end if;
            
            s_xor_carr2_2 <= sync_dat xor s_carr2_2;
            s_xor_carr2_2_r <= s_xor_carr2_2;
            s_xor_carr2_2_rr <= s_xor_carr2_2_r;
            if( s_carr2_2_r = '1')then
                s_smsg_ph2_1 <= s_xor_carr2_2 xor s_xor_carr2_2_rr;
            else   
                s_smsg_ph2_2 <= s_xor_carr2_2 xor s_xor_carr2_2_rr;
            end if;
            
        end if;
    end process;
    
    
    --==========================================================================
    -- Назначение выходных сигналов
    --==========================================================================
    fmsg_ph1  <= s_fmsg_ph1;
    fmsg_ph2  <= s_fmsg_ph2;
    
    smsg_ph11 <= s_smsg_ph1_1;
    smsg_ph12 <= s_smsg_ph1_2;
    smsg_ph21 <= s_smsg_ph2_1;
    smsg_ph22 <= s_smsg_ph2_2;
    
end beh;
