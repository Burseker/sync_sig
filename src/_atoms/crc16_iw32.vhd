--=============================
-- Developed by SVB. Ver. 1.3.0
--=============================
----------------------------------------------------------------------------------
-- Company: Дизайн-центр
-- Engineer: Сергей Бураков
-- 
-- Create Date: 
-- Design Name: 
-- Module Name:    crc16_iw32 - beh
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:  	
--	Блок вычисления контрольной суммы CRC16-CCITT
--	Порождающий полином:
--	G(x) = x^16 + x^12 + x^5 + 1
--
-- Dependencies:
--
-- Version History:
-- Ver 1.0.0 - (17/01/2013) Черновая версия
-- Ver 1.1.0 - Добавлен параметр IBIT_REV.
--             Включает зеркальную коммутацию входной шины данных.
--             А так, же подает младшую часть входного сигнала на
--             первый xor в цепочке.
--             Используется в представлении данных little-endian.
-- Ver 1.2.0 - Добавлен параметр IBYTE_REV.
--             Комутирует входные данные таким образом, что первым
--             на расчет контрольной суммы поступает младший байт
--             входного слова. При этом в байте первым считается 
--             старший разряд
-- Ver 1.3.0 - Исключен generic параметр OREG(за отсутствием в нем смысла)).
--             Результат контрольной суммы теперь снимается с сигнала s_mx_x
--             При этом сигнал rst не уничтожает контрольную сумму, полученную из
--             данных, действующих вместе с rst. 
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

entity crc16_iw32 is
    generic (
        INIT        : std_logic_vector(15 downto 0) := (others=>'0');
        IBIT_REV    : boolean := false;
        IBYTE_REV   : boolean := false
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        ena         : in  std_logic;
        idat        : in  std_logic_vector(31 downto 0);
        odateven    : out std_logic_vector(15 downto 0);
        odatodd     : out std_logic_vector(15 downto 0)
    );
end crc16_iw32;

architecture beh of crc16_iw32 is

    function bit_reverse(v: std_logic_vector) return std_logic_vector is
    alias vx        : std_logic_vector(v'length-1 downto 0) is v;
    variable res    : std_logic_vector(vx'range);
    begin
        for i in vx'range loop
            res(vx'high - i) := vx(i);
        end loop;
        return(res);
    end bit_reverse;
    
    signal s_idat1    : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_idat2    : std_logic_vector(15 downto 0) := (others=>'0');
    
    signal rgeven     : std_logic_vector(15 downto 0) := INIT; -- регистр
    signal rgodd      : std_logic_vector(15 downto 0) := (others=>'0'); -- регистр
    signal s_m1_1     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_m1_2     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_m2_1     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_m2_2     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_odateven : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_odatodd  : std_logic_vector(15 downto 0) := (others=>'0');

begin
    
    --==================================================
    -- Комутация входного порта
    bitrevoff_byterevoff: if( IBIT_REV = false and IBYTE_REV = false ) generate
        s_idat1 <= idat(31 downto 16); 
        s_idat2 <= idat(15 downto 0);
    end generate bitrevoff_byterevoff;

    bitrevoff_byterevon: if( IBIT_REV = false and IBYTE_REV = true ) generate
        s_idat1 <= idat(7 downto 0)   & idat(15 downto 8);
        s_idat2 <= idat(23 downto 16) & idat(31 downto 24);
    end generate bitrevoff_byterevon;
    
    bitrevon_byterevoff: if( IBIT_REV = true and IBYTE_REV = false ) generate
        s_idat1 <= bit_reverse(idat(15 downto 0));
        s_idat2 <= bit_reverse(idat(31 downto 16));
    end generate bitrevon_byterevoff;
    
    assert not( IBIT_REV = true and IBYTE_REV = true )
        report "Wrong value of parameter 'IBIT_REV' and 'IBYTE_REV'. It should not be true value bouth" 
	severity ERROR;

    --==================================================
    -- REG
    reg_prc: process(clk) -- регистр
    begin
        if(rising_edge(clk))then
            if(rst = '1')then
                rgeven <= INIT;
                rgodd  <= (others=>'0');
            elsif(ena = '1')then
                rgeven <= s_m2_2;
                rgodd  <= s_m1_2;
            end if;
        end if;
    end process;
  
  
    --==================================================
    s_m1_1 <= rgeven xor s_idat1;
    
    s_m1_2(15) <= s_m1_1(11) xor s_m1_1(10) xor s_m1_1(7)  xor s_m1_1(3);
    s_m1_2(14) <= s_m1_1(10) xor s_m1_1(9)  xor s_m1_1(6)  xor s_m1_1(2);
    s_m1_2(13) <= s_m1_1(9)  xor s_m1_1(8)  xor s_m1_1(5)  xor s_m1_1(1);
    s_m1_2(12) <= s_m1_1(15) xor s_m1_1(8)  xor s_m1_1(7)  xor s_m1_1(4)  xor s_m1_1(0);
    s_m1_2(11) <= s_m1_1(15) xor s_m1_1(14) xor s_m1_1(11) xor s_m1_1(10) xor s_m1_1(6);
    s_m1_2(10) <= s_m1_1(14) xor s_m1_1(13) xor s_m1_1(10) xor s_m1_1(9)  xor s_m1_1(5);
    s_m1_2(9)  <= s_m1_1(15) xor s_m1_1(13) xor s_m1_1(12) xor s_m1_1(9)  xor s_m1_1(8)  xor s_m1_1(4);
    s_m1_2(8)  <= s_m1_1(15) xor s_m1_1(14) xor s_m1_1(12) xor s_m1_1(11) xor s_m1_1(8)  xor s_m1_1(7) xor s_m1_1(3);
    s_m1_2(7)  <= s_m1_1(15) xor s_m1_1(14) xor s_m1_1(13) xor s_m1_1(11) xor s_m1_1(10) xor s_m1_1(7) xor s_m1_1(6) xor s_m1_1(2);
    s_m1_2(6)  <= s_m1_1(14) xor s_m1_1(13) xor s_m1_1(12) xor s_m1_1(10) xor s_m1_1(9)  xor s_m1_1(6) xor s_m1_1(5) xor s_m1_1(1);
    s_m1_2(5)  <= s_m1_1(13) xor s_m1_1(12) xor s_m1_1(11) xor s_m1_1(9)  xor s_m1_1(8)  xor s_m1_1(5) xor s_m1_1(4) xor s_m1_1(0);
    s_m1_2(4)  <= s_m1_1(15) xor s_m1_1(12) xor s_m1_1(8)  xor s_m1_1(4);
    s_m1_2(3)  <= s_m1_1(15) xor s_m1_1(14) xor s_m1_1(11) xor s_m1_1(7)  xor s_m1_1(3);
    s_m1_2(2)  <= s_m1_1(14) xor s_m1_1(13) xor s_m1_1(10) xor s_m1_1(6)  xor s_m1_1(2);
    s_m1_2(1)  <= s_m1_1(13) xor s_m1_1(12) xor s_m1_1(9)  xor s_m1_1(5)  xor s_m1_1(1);
    s_m1_2(0)  <= s_m1_1(12) xor s_m1_1(11) xor s_m1_1(8)  xor s_m1_1(4)  xor s_m1_1(0);
  
  
    --==================================================
    s_m2_1 <= s_m1_2 xor s_idat2;

    s_m2_2(15) <= s_m2_1(11) xor s_m2_1(10) xor s_m2_1(7)  xor s_m2_1(3);
    s_m2_2(14) <= s_m2_1(10) xor s_m2_1(9)  xor s_m2_1(6)  xor s_m2_1(2);
    s_m2_2(13) <= s_m2_1(9)  xor s_m2_1(8)  xor s_m2_1(5)  xor s_m2_1(1);
    s_m2_2(12) <= s_m2_1(15) xor s_m2_1(8)  xor s_m2_1(7)  xor s_m2_1(4)  xor s_m2_1(0);
    s_m2_2(11) <= s_m2_1(15) xor s_m2_1(14) xor s_m2_1(11) xor s_m2_1(10) xor s_m2_1(6);
    s_m2_2(10) <= s_m2_1(14) xor s_m2_1(13) xor s_m2_1(10) xor s_m2_1(9)  xor s_m2_1(5);
    s_m2_2(9)  <= s_m2_1(15) xor s_m2_1(13) xor s_m2_1(12) xor s_m2_1(9)  xor s_m2_1(8)  xor s_m2_1(4);
    s_m2_2(8)  <= s_m2_1(15) xor s_m2_1(14) xor s_m2_1(12) xor s_m2_1(11) xor s_m2_1(8)  xor s_m2_1(7) xor s_m2_1(3);
    s_m2_2(7)  <= s_m2_1(15) xor s_m2_1(14) xor s_m2_1(13) xor s_m2_1(11) xor s_m2_1(10) xor s_m2_1(7) xor s_m2_1(6) xor s_m2_1(2);
    s_m2_2(6)  <= s_m2_1(14) xor s_m2_1(13) xor s_m2_1(12) xor s_m2_1(10) xor s_m2_1(9)  xor s_m2_1(6) xor s_m2_1(5) xor s_m2_1(1);
    s_m2_2(5)  <= s_m2_1(13) xor s_m2_1(12) xor s_m2_1(11) xor s_m2_1(9)  xor s_m2_1(8)  xor s_m2_1(5) xor s_m2_1(4) xor s_m2_1(0);
    s_m2_2(4)  <= s_m2_1(15) xor s_m2_1(12) xor s_m2_1(8)  xor s_m2_1(4);
    s_m2_2(3)  <= s_m2_1(15) xor s_m2_1(14) xor s_m2_1(11) xor s_m2_1(7)  xor s_m2_1(3);
    s_m2_2(2)  <= s_m2_1(14) xor s_m2_1(13) xor s_m2_1(10) xor s_m2_1(6)  xor s_m2_1(2);
    s_m2_2(1)  <= s_m2_1(13) xor s_m2_1(12) xor s_m2_1(9)  xor s_m2_1(5)  xor s_m2_1(1);
    s_m2_2(0)  <= s_m2_1(12) xor s_m2_1(11) xor s_m2_1(8)  xor s_m2_1(4)  xor s_m2_1(0);

  
    --==================================================
    -- Output
    out_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(ena = '1')then
                s_odateven <= s_m2_2;
                s_odatodd  <= s_m1_2;
            end if;
        end if;
    end process;

    -- oreg_false_gen: if (OREG = false) generate
        -- s_odateven <= rgeven;
        -- s_odatodd  <= rgodd;
    -- end generate;
  
    odateven    <= s_odateven;
    odatodd     <= s_odatodd;
    
end beh;
