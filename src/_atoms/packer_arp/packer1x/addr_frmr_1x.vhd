--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 1.2
--Application: 
--Filename: addr_frmr_1x.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5
--Design Name: �������
--Purpose:    addr_frmr_1x - ���� ���������� ������ ��� flex_packer
--        ��������� ����� i_width �� ������ OWIDTH � �����������
--        * �������: mux = (mux + i_width) % OWIDTH
--
--Dependencies:
--
--Reference:
--    * �� ������ addr_frmr ������������ flex_unpacker
--
--Revision History:
--    Revision 0.1.0 (20/09/2011) - ������ ������
--    Revision 0.1.1 (29/09/2011) - o_align
--        + �������� ���� o_align - ������, ��� �� ��������� ����
--          ����� ����� ��������� �� ������ ��������
--    Revision 0.1.2 (10/10/2014) - ���� ������������ addr_frmr_1x
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_frmr_1x is
  generic (
    OPWIDTH : integer := 6;  -- ����������� ���������
    OWIDTH  : integer := 32; -- �������� ����������� flex_packer
    INIT    : integer := 0   -- ��������� �������� ��������� ��������
  );
  port (
    clk     : in  std_logic;
    sclr    : in  std_logic;
    
    i_ena   : in  std_logic; -- ������ �����
    i_width : in  std_logic_vector(OPWIDTH-1 downto 0); -- ������� ����������� flex_packer
    o_hop   : out std_logic;
    o_align : out std_logic;
    o_addr  : out std_logic_vector(OPWIDTH-1 downto 0)  -- ����� �� �����
  );
end addr_frmr_1x;

architecture syn of addr_frmr_1x is

  constant c_zeros : std_logic_vector(OPWIDTH-2 downto 0) := (others=>'0');

  signal sum       : std_logic_vector(OPWIDTH-1 downto 0) := (others=>'0');
  signal sub       : std_logic_vector(OPWIDTH-1 downto 0) := (others=>'0');
  signal mux       : std_logic_vector(OPWIDTH-2 downto 0) := std_logic_vector(to_unsigned(INIT, OPWIDTH-1));
  
  signal sign_sub  : std_logic := '0';
  signal rgnum     : std_logic := '0';
  
begin

  --==================================================
  -- ��������-����������
  sum_prc: process(i_width, mux)
    variable v_mux : std_logic_vector(OPWIDTH-1 downto 0) := (others=>'0');
  begin
    v_mux := '0' & mux;
    sum   <= std_logic_vector(unsigned(i_width) + unsigned(v_mux));
  end process;
  
  
  --==================================================
  -- ����������
  sub_prc: process(sum)
  begin
    sub <= std_logic_vector(unsigned(sum) - to_unsigned(OWIDTH, OPWIDTH));
  end process;
  
  sign_sub <= sub(sub'length-1); -- �������� ������ sub
  
  
  --==================================================
  -- �������������
  mux_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(sclr = '1')then
            mux <= std_logic_vector(to_unsigned(INIT, OPWIDTH-1));
        elsif(i_ena = '1')then
            if(sign_sub = '1')then -- ���� sub �������������
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
        if(sclr = '1')then
            rgnum <= '0';
        elsif(i_ena = '1' and sign_sub = '0')then
            rgnum <= not rgnum;
        end if;
    end if;
  end process;
  
  o_addr <= rgnum & mux;
  
  
  --==================================================
  -- ������ o_hop - � ��������� ����� i_ena ����� 
  -- ������ ������ �� ������ �������
  o_hop <= not sign_sub;
  
  
  --==================================================
  -- ������ o_align - � ��������� ����� i_ena �����
  -- ����� ��������� �� ������ ��������, ��������
  o_align <= '1' when (sub(OPWIDTH-2 downto 0) = c_zeros) else '0';
  
  
end syn;
