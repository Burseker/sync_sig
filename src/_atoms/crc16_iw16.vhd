--=============================
-- Developed by ARP. Ver. 1.4.0
--=============================
----------------------------------------------------------------------------------
-- Company: Дизайн-центр
-- Engineer: Бураков Сергей, Рябков Андрей
-- 
-- Create Date: 
-- Design Name: 
-- Module Name:    crc16_iw16 - syn 
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
-- Revision: 
-- Ver 1.0.0 - (18/06/2012) Черновая версия
-- Ver 1.1.0 - (18/06/2012) Первая версия(рабочая)
--					не тестировалась в симуляторе
-- Ver 1.2.0 - Добавлен параметр REFIN.
--             Включает зеркальную коммутацию входной шины данных.
--             Используется в представлении данных little-endian
-- Ver 1.3.0 - Добавлен параметр IBYTE_REV.
--             Комутирует входные данные таким образом, что первым
--             на расчет контрольной суммы поступает младший байт
--             входного слова. При этом в байте первым считается 
--             старший разряд
-- Ver 1.4.0 - Исключен generic параметр OREG(за отсутствием в нем смысла)).
--             Результат контрольной суммы теперь снимается с сигнала s_mx
--             При этом сигнал rst не уничтожает контрольную сумму, полученную из
--             данных, действующих вместе с rst.
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity crc16_iw16 is
    generic (
        INIT        : std_logic_vector(15 downto 0) := (others=>'0');
        IBIT_REV    : boolean := false;
        IBYTE_REV   : boolean := false
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        ena     : in  std_logic;
        input   : in  std_logic_vector(15 downto 0);
        output  : out std_logic_vector(15 downto 0)
    );
end crc16_iw16;

architecture syn of crc16_iw16 is

    function bit_reverse(v: std_logic_vector) return std_logic_vector is
    alias vx        : std_logic_vector(v'length-1 downto 0) is v;
    variable res    : std_logic_vector(vx'range);
    begin
        for i in vx'range loop
            res(vx'high - i) := vx(i);
        end loop;
        return(res);
    end bit_reverse;
    
    
    signal s_idat   : std_logic_vector(15 downto 0) := (others=>'0'); -- регистр
    
    signal reg      : std_logic_vector(15 downto 0) := INIT; -- регистр
    signal s_m1     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_m2     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_output : std_logic_vector(15 downto 0) := (others=>'0');

begin

    --==================================================
    -- Комутация входного порта
    bitrevoff_byterevoff: if( IBIT_REV = false and IBYTE_REV = false ) generate
        s_idat <= input;
    end generate bitrevoff_byterevoff;

    bitrevoff_byterevon: if( IBIT_REV = false and IBYTE_REV = true ) generate
        s_idat <= input(7 downto 0) & input(15 downto 8);
    end generate bitrevoff_byterevon;
    
    bitrevon_byterevoff: if( IBIT_REV = true and IBYTE_REV = false ) generate
        s_idat <= bit_reverse(input);
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
                reg <= INIT;
            elsif(ena = '1')then
                reg <= s_m2;
            end if;
        end if;
    end process;
  
  
    --==================================================
    s_m1 <= reg xor s_idat;
    
    s_m2(15) <= s_m1(11) xor s_m1(10) xor s_m1(7)  xor s_m1(3);
    s_m2(14) <= s_m1(10) xor s_m1(9)  xor s_m1(6)  xor s_m1(2);
    s_m2(13) <= s_m1(9)  xor s_m1(8)  xor s_m1(5)  xor s_m1(1);
    s_m2(12) <= s_m1(15) xor s_m1(8)  xor s_m1(7)  xor s_m1(4)  xor s_m1(0);
    s_m2(11) <= s_m1(15) xor s_m1(14) xor s_m1(11) xor s_m1(10) xor s_m1(6);
    s_m2(10) <= s_m1(14) xor s_m1(13) xor s_m1(10) xor s_m1(9)  xor s_m1(5);
    s_m2(9)  <= s_m1(15) xor s_m1(13) xor s_m1(12) xor s_m1(9)  xor s_m1(8)  xor s_m1(4);
    s_m2(8)  <= s_m1(15) xor s_m1(14) xor s_m1(12) xor s_m1(11) xor s_m1(8)  xor s_m1(7) xor s_m1(3);
    s_m2(7)  <= s_m1(15) xor s_m1(14) xor s_m1(13) xor s_m1(11) xor s_m1(10) xor s_m1(7) xor s_m1(6) xor s_m1(2);
    s_m2(6)  <= s_m1(14) xor s_m1(13) xor s_m1(12) xor s_m1(10) xor s_m1(9)  xor s_m1(6) xor s_m1(5) xor s_m1(1);
    s_m2(5)  <= s_m1(13) xor s_m1(12) xor s_m1(11) xor s_m1(9)  xor s_m1(8)  xor s_m1(5) xor s_m1(4) xor s_m1(0);
    s_m2(4)  <= s_m1(15) xor s_m1(12) xor s_m1(8)  xor s_m1(4);
    s_m2(3)  <= s_m1(15) xor s_m1(14) xor s_m1(11) xor s_m1(7)  xor s_m1(3);
    s_m2(2)  <= s_m1(14) xor s_m1(13) xor s_m1(10) xor s_m1(6)  xor s_m1(2);
    s_m2(1)  <= s_m1(13) xor s_m1(12) xor s_m1(9)  xor s_m1(5)  xor s_m1(1);
    s_m2(0)  <= s_m1(12) xor s_m1(11) xor s_m1(8)  xor s_m1(4)  xor s_m1(0);

  
    --==================================================
    -- Output
    out_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(ena = '1')then
                s_output <= s_m2;
            end if;
        end if;
    end process;
    output <= s_output;
  
end syn;
