-- =============================================================================
-- Description: packerx1 address former
-- Version:     1.7
-- Designer:    ARP
-- Workgroup:   IRS
-- =============================================================================
-- Keywords:    Packer, Address Former
-- Tools:       Altera Quartus II 9.1
--
-- Dependencies:
--
-- Details: addr_frmr_x1 - блок вычисления адреса для packerx1
--        Суммирует число OWIDTH по модулю i_width с накоплением
--        * Формула: mux = (mux + OWIDTH) % i_width
--
--Revision History:
--    Revision 1.0 (15/08/2011) - Первая версия
--    Revision 1.1 (15/08/2011) - Старший разряд
--        * Старший разряд в o_addr указывает, в каком из двух
--          регистров packerx1 забирать бит
--    Revision 1.2 (15/08/2011) - Порт switch
--        + Добавлен порт switch - сигнал, что блок переключился 
--          на другой регистр
--    Revision 1.3 (17/08/2011) - Порт o_hop
--        * Переименованы порты: i_xx - входные, o_xx - выходные
--        - Убран порт switch
--        + Добавлен порт o_hop - в следующий строб i_ena будет
--          прыжок адреса на другой регистр
--        * Сигнал align показывает, что следующее по стробу i_ena
--          слово будет выровнено по границе регистра
--    Revision 1.3 (18/08/2011) - Порт o_hop
--        - Убран лишний сигнал align
--    Revision 1.4 (19/08/2011) - Расширение знакового разряда
--        + Добавлено расширение знакового разряда перед
--          сумматором sum и вычитателем sub
--        * Так как суммирование по модулю i_width (с разрядностью
--          OPWIDTH), то результат на выходе sum или sub перед
--          мультиплексором mux будет иметь OPWIDTH значащих 
--          младших бит, старшие разряды можно отбросить
--    Revision 1.5 (24/08/2011) - Разрядность операндов
--        * Разрядность i_width и o_addr одинаковая
--        * Переработаны сумматор и вычитатель
--        * Параметр OPWIDTH увеличен на 1
--    Revision 1.6 (10/10/2014) - Блок переименован addr_frmr_x1
--    Revision 1.7 (20/02/2015) - Косметические изменения
--
--
-- -----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_frmr_x1 is
 generic (
    OPWIDTH : integer := 7;  -- разрядность операндов
    OWIDTH  : integer := 16; -- выходная разрядность packerx1
    INIT    : integer := 0   -- начальное значение выходного регистра
 );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;

    i_ena   : in  std_logic; -- выдать адрес
    i_width : in  std_logic_vector(OPWIDTH-1 downto 0); -- входная разрядность packerx1
    o_hop   : out std_logic;
    o_addr  : out std_logic_vector(OPWIDTH-1 downto 0)  -- адрес на выход
  );
end addr_frmr_x1;

architecture syn of addr_frmr_x1 is

  signal sum : unsigned(OPWIDTH-1 downto 0) := (others=>'0');
  signal sub : unsigned(OPWIDTH-1 downto 0) := (others=>'0');
  signal mux : unsigned(OPWIDTH-2 downto 0) := to_unsigned(INIT, OPWIDTH-1);

  signal sub_sign : std_logic := '0';
  signal reg_num  : std_logic := '0';

begin

  --==================================================
  -- Сумматор-накопитель
  sum_prc: process(mux)
    variable v_mux : unsigned(OPWIDTH-1 downto 0) := (others=>'0');
  begin
    v_mux := '0' & mux;
    sum   <= to_unsigned(OWIDTH, OPWIDTH) + v_mux;
  end process;


  --==================================================
  -- Вычитатель
  sub_prc: process(sum, i_width)
  begin
    sub   <= sum - unsigned(i_width);
  end process;

  sub_sign <= sub(sub'length-1); -- знаковый разряд sub


  --==================================================
  -- Мультиплексор
  mux_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(rst = '1')then
            mux <= to_unsigned(INIT, OPWIDTH-1);
        elsif(i_ena = '1')then
            if(sub_sign = '1')then -- если sub отрицательное
                mux <= sum(OPWIDTH-2 downto 0);
            else
                mux <= sub(OPWIDTH-2 downto 0);
            end if;
        end if;
    end if;
  end process;


  --==================================================
  -- Самый старший разряд адреса -
  -- выбор одного из двух регистров
  rgnum_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(rst = '1')then
            reg_num <= '0';
        elsif(i_ena = '1' and sub_sign = '0')then
            reg_num <= not reg_num;
        end if;
    end if;
  end process;

  o_addr <= std_logic_vector(reg_num & mux);


  --==================================================
  -- Сигнал o_hop - в следующий строб i_ena будет 
  -- прыжок адреса на другой регистр
  o_hop <= not sub_sign;


end syn;
