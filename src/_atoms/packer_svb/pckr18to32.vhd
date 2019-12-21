--=============================
-- Developed by SVB. Ver. 0.2.0 
--=============================
----------------------------------------------------------------------------------
-- Company:         Дизайн-центр
-- Engineer:        Сергей Бураков
--                  
-- Create Date:     30.12.2014
-- Design Name:     pckr18to32
-- Module Name:     pckr18to32 - Beh
-- Project Name:    Quartet
-- Target Devices:  Stratix II: EP2S60F484I4
-- Tool versions:   Notepad++
-- Description:     Перепаковка пакетного потока из 18и в 32ти
--                  разряднй код
--                  
--                  
-- Dependencies:    
--                  
-- Revision:        
-- Revision 0.0.0 - File created   
-- Revision 0.1.0 - Составной блок из pckr18to24 и pckr24to32
-- Revision 0.2.0 - Добавлен параметр перепаковки ENDIANNESS
--                  
--
--
--                  
-- Additional Comments: 
-- 
--     
-- 
-- 
-- 
-- 
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use work.pkg_sim.all;
use work.pkg_func.all;
--=========================

entity pckr18to32 is
    generic(
        ENDIANNESS : string := "BIG_ENDIAN" -- "BIG_ENDIAN", "LITTLE_ENDIAN"
    );
    port (
        aclr    : in  std_logic;
        clk     : in  std_logic;
        
        idat    : in  std_logic_vector(17 downto 0);
        istb    : in  std_logic;
        iend    : in  std_logic;
        iten    : out std_logic;
        
        odat    : out std_logic_vector(31 downto 0);
        ostb    : out std_logic;
        oend    : out std_logic;
        oten    : in  std_logic
    );
end pckr18to32;

architecture beh of pckr18to32 is

    constant C_IWIDTH   : natural := 18;
    constant C_OWIDTH   : natural := 32;
    
    signal s_iten        : std_logic := '0';
    
    signal s_adat        : std_logic_vector( 23 downto 0) := (others => '0');
    signal s_aend        : std_logic := '0';
    signal s_astb        : std_logic := '0';
    signal s_aten        : std_logic := '0';
    
    signal s_odat        : std_logic_vector( C_OWIDTH-1 downto 0) := (others => '0');
    signal s_oend        : std_logic := '0';
    signal s_ostb        : std_logic := '0';
    
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
--РАСПАКОВКА ПАКЕТОВ К 16
--=============================================
pckr8to16inst: entity work.pckr18to24
generic map( ENDIANNESS => ENDIANNESS)
port map(
    aclr    => aclr,
    clk     => clk,
    
    idat    => idat,
    istb    => istb,
    iend    => iend,
    iten    => s_iten,
    
    odat    => s_adat,
    ostb    => s_astb,
    oend    => s_aend,
    oten    => s_aten
);


--=============================================
--РАСПАКОВКА ПАКЕТОВ К 18
--=============================================
pckr16to18inst: entity work.pckr24to32
generic map( ENDIANNESS => ENDIANNESS)
port map(
    aclr    => aclr,
    clk     => clk,
    
    idat    => s_adat,
    istb    => s_astb,
    iend    => s_aend,
    iten    => s_aten,
    
    odat    => s_odat,
    ostb    => s_ostb,
    oend    => s_oend,
    oten    => oten
);


--==================================
-- Назначение выходных сигналов
--==================================   
    iten <= s_iten;
    
    odat <= s_odat;
    ostb <= s_ostb;
    oend <= s_oend;
    
end Beh;
