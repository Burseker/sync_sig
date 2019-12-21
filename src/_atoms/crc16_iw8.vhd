--================================================================================
-- Description: Блок рассчета контрольной суммы CRC16-CCITT
-- Version:     1.2.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    CRC16-CCITT
-- Tools:       Altera Quartus 9.1 SP1
--              
-- Note:
--	Блок вычисления контрольной суммы CRC16-CCITT
--	Порождающий полином:
--	G(x) = x^16 + x^12 + x^5 + 1
-- 
-- 
-- Version History:
-- Ver 1.0.0 - File create
-- Ver 1.1.0 - Добавлен параметр IBIT_REV.
--             Включает зеркальную коммутацию входной шины данных.
--             Используется в представлении данных little-endian
-- Ver 1.2.0 - Исключен generic параметр OREG(за отсутствием в нем смысла)).
--             Результат контрольной суммы теперь снимается с сигнала s_mx
--             При этом сигнал rst не уничтожает контрольную сумму, полученную из
--             данных, действующих вместе с rst. 
-- 
----------------------------------------------------------------------------------
-- <метка>: entity work.crc16_iw8
-- generic map(
    -- OREG    => ,
    -- INIT    => ,
    -- REFIN   => 
-- )
-- port map(
    -- clk     => ,
    -- rst     => ,
    -- ena     => ,
    -- idat    => ,
    -- odat    => 
-- );
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc16_iw8 is
  generic (
	INIT    : std_logic_vector(15 downto 0) := (others=>'0');
    IBIT_REV   : boolean := false
  );
  port (
	clk     : in  std_logic;
	rst     : in  std_logic;
	ena     : in  std_logic;
	idat    : in  std_logic_vector(7  downto 0);
	odat    : out std_logic_vector(15 downto 0)
  );
end crc16_iw8;

architecture beh of crc16_iw8 is

    function bit_reverse(v: std_logic_vector) return std_logic_vector is
    alias vx        : std_logic_vector(v'length-1 downto 0) is v;
    variable res    : std_logic_vector(vx'range);
    begin
        for i in vx'range loop
            res(vx'high - i) := vx(i);
        end loop;
        return(res);
    end bit_reverse;
    
    signal s_idat   : std_logic_vector(7 downto 0) := (others=>'0');
    
    signal reg      : std_logic_vector(15 downto 0) := INIT; -- регистр
    signal s_m1     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_m2     : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_output : std_logic_vector(15 downto 0) := (others=>'0');

begin
    bitrevoff: if( IBIT_REV = false ) generate
        s_idat <= idat;
    end generate bitrevoff;
    
    bitrevon: if( IBIT_REV = true ) generate
        s_idat <= bit_reverse(idat);
    end generate bitrevon;

    --==================================================
    -- REG
    --==================================================
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
    s_m1(15 downto 8) <= reg(15 downto 8) xor s_idat;
    s_m1(7  downto 0) <= reg(7  downto 0);
        
    s_m2(15) <= s_m1(7)  xor s_m1(11) xor s_m1(15);
    s_m2(14) <= s_m1(6)  xor s_m1(10) xor s_m1(14);
    s_m2(13) <= s_m1(5)  xor s_m1(9)  xor s_m1(13);
    s_m2(12) <= s_m1(4)  xor s_m1(8)  xor s_m1(12) xor s_m1(15);
    s_m2(11) <= s_m1(3)  xor s_m1(14);
    s_m2(10) <= s_m1(2)  xor s_m1(13);
    s_m2(9)  <= s_m1(1)  xor s_m1(12);
    s_m2(8)  <= s_m1(0)  xor s_m1(11) xor s_m1(15);

    s_m2(7)  <= s_m1(10) xor s_m1(14) xor s_m1(15);
    s_m2(6)  <= s_m1(9)  xor s_m1(13) xor s_m1(14);
    s_m2(5)  <= s_m1(8)  xor s_m1(12) xor s_m1(13);
    s_m2(4)  <= s_m1(12);
    s_m2(3)  <= s_m1(11) xor s_m1(15);
    s_m2(2)  <= s_m1(10) xor s_m1(14);
    s_m2(1)  <= s_m1(9)  xor s_m1(13);
    s_m2(0)  <= s_m1(8)  xor s_m1(12);

    --==================================================
    -- odat
    --==================================================
    out_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(ena = '1')then
                s_output <= s_m2;
            end if;
        end if;
    end process;
    odat <= s_output;
    
end beh;
