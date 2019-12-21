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
-- Details: addr_frmr_x1 - ���� ���������� ������ ��� packerx1
--        ��������� ����� OWIDTH �� ������ i_width � �����������
--        * �������: mux = (mux + OWIDTH) % i_width
--
--Revision History:
--    Revision 1.0 (15/08/2011) - ������ ������
--    Revision 1.1 (15/08/2011) - ������� ������
--        * ������� ������ � o_addr ���������, � ����� �� ����
--          ��������� packerx1 �������� ���
--    Revision 1.2 (15/08/2011) - ���� switch
--        + �������� ���� switch - ������, ��� ���� ������������ 
--          �� ������ �������
--    Revision 1.3 (17/08/2011) - ���� o_hop
--        * ������������� �����: i_xx - �������, o_xx - ��������
--        - ����� ���� switch
--        + �������� ���� o_hop - � ��������� ����� i_ena �����
--          ������ ������ �� ������ �������
--        * ������ align ����������, ��� ��������� �� ������ i_ena
--          ����� ����� ��������� �� ������� ��������
--    Revision 1.3 (18/08/2011) - ���� o_hop
--        - ����� ������ ������ align
--    Revision 1.4 (19/08/2011) - ���������� ��������� �������
--        + ��������� ���������� ��������� ������� �����
--          ���������� sum � ����������� sub
--        * ��� ��� ������������ �� ������ i_width (� ������������
--          OPWIDTH), �� ��������� �� ������ sum ��� sub �����
--          ��������������� mux ����� ����� OPWIDTH �������� 
--          ������� ���, ������� ������� ����� ���������
--    Revision 1.5 (24/08/2011) - ����������� ���������
--        * ����������� i_width � o_addr ����������
--        * ������������ �������� � ����������
--        * �������� OPWIDTH �������� �� 1
--    Revision 1.6 (10/10/2014) - ���� ������������ addr_frmr_x1
--    Revision 1.7 (20/02/2015) - ������������� ���������
--
--
-- -----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_frmr_x1 is
 generic (
    OPWIDTH : integer := 7;  -- ����������� ���������
    OWIDTH  : integer := 16; -- �������� ����������� packerx1
    INIT    : integer := 0   -- ��������� �������� ��������� ��������
 );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;

    i_ena   : in  std_logic; -- ������ �����
    i_width : in  std_logic_vector(OPWIDTH-1 downto 0); -- ������� ����������� packerx1
    o_hop   : out std_logic;
    o_addr  : out std_logic_vector(OPWIDTH-1 downto 0)  -- ����� �� �����
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
  -- ��������-����������
  sum_prc: process(mux)
    variable v_mux : unsigned(OPWIDTH-1 downto 0) := (others=>'0');
  begin
    v_mux := '0' & mux;
    sum   <= to_unsigned(OWIDTH, OPWIDTH) + v_mux;
  end process;


  --==================================================
  -- ����������
  sub_prc: process(sum, i_width)
  begin
    sub   <= sum - unsigned(i_width);
  end process;

  sub_sign <= sub(sub'length-1); -- �������� ������ sub


  --==================================================
  -- �������������
  mux_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(rst = '1')then
            mux <= to_unsigned(INIT, OPWIDTH-1);
        elsif(i_ena = '1')then
            if(sub_sign = '1')then -- ���� sub �������������
                mux <= sum(OPWIDTH-2 downto 0);
            else
                mux <= sub(OPWIDTH-2 downto 0);
            end if;
        end if;
    end if;
  end process;


  --==================================================
  -- ����� ������� ������ ������ -
  -- ����� ������ �� ���� ���������
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
  -- ������ o_hop - � ��������� ����� i_ena ����� 
  -- ������ ������ �� ������ �������
  o_hop <= not sub_sign;


end syn;
