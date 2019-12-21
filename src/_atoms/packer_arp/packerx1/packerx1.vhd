-- =============================================================================
-- Description: packerx1
-- Version:     1.6
-- Designer:    ARP
-- Workgroup:   IRS
-- =============================================================================
-- Keywords:    Packerx1
-- Tools:       Altera Quartus II 9.1
--
--Device: 
--Design Name: Packer
--Purpose:    packerx1 - ������ �����������
--        * ����������� ������� ���� ����� ��������
--          � �������� ������, ���� i_width
--        * ����������� �������� ���� �������� ���
--          ����������, �������� OWIDTH
--
--Dependencies: 
--        * ��� ��� ���� �������� ������������� ����, �� OWIDTH 
--          ������ ���� ������ ������ i_width
--        * ����� ����� i_width ���� ������� ������ sclr
--        * i_width ��������� �������� �� 1 �� IMWIDTH
--        * �������� IMWIDTH ������ ���� ������ ������� 2
--          ������������ �������� ��������� ����������� �������������
--        * ����� FIFO ������ ����� ��������� �������� fifo_v1_21,
--          �� ���� �� ������� ������ rden ������ ������ � ���� �� �����
--          (first word fall through).
--        * ������� ����� ������ ��������� ������� ��� �����
--
--Reference:
--Revision History:
--    Revision 1.0 (19/08/2011) - ������ ������
--        * ���������� ��������� ������ �� �������. ��� ����������
--          fsm_load_null � �������� ������������ �������� ����� 
--          FIFO � ������� (����� ������ FIFO �� ��������).
--        * ����� ����������� � �������� ������� ����� ��� ���� ��������:
--          1 - ���� ����� FIFO ������, �� �� ������ ������ ������� �����.
--              ����� fifo_v1_21 ��� �� �����.
--          2 - ���� ��� ��������� i_fifo_end ����� ����� �����������
--              ����� ������
--        * ��������� ������ ������ �������� ��������� IMWIDTH = 64
--        * addr_hop ����������� ���������� � addr_frmr. ����� 
--          ����������� ������� ���������� addr_hop. ��� ����� 
--          ������ ����������� �� ��� ������, ����������� ��������� �
--          addr_frmr. ����� ����������� OWIDTH = 3
--    Revision 1.1 (24/08/2011) - ����� ������� i_width = IMWIDTH
--        * ����������� i_width ��������� �� 1
--        * ����������� addr_frmr - ������ 0.1.5
--        * ������������ �������� IGWIDTH �� IMWIDTH
--        - �� ������ �������� ������� ����� � �����, ����
--          i_width = OWIDTH
--    Revision 1.2 (11/11/2011) - ������ ������ ������
--        * ���� ������������ flex_unpacker -> packerx1
--        * ���������� ��������� ������ ������ ������:
--          ��������� ������� i_fifo_str, i_fifo_end ���������
--          ������� i_fifo_empty = 0
--    Revision 1.3 (10/10/2014) - ������������ ����������� ������
--        * addr_frmr -> addr_frmr_x1
--    Revision 1.4 (24/10/2014) - ������������ ����������� ������� ����
--        * ������ ������ ������ ������� ������ (�������� IMWIDTH)
--        * � ���������� ������� �������������� ������ IMWIDTH = 64
--        * ����� ������������� mux128_1_r -> muxN_1_r
--    Revision 1.5 (24/02/2015) - ENDIANNESS
--        * �������� �������� ENDIANNESS
--        * ENDIANNESS = LITTLE-ENDIAN: �����������
--          ������ �� ���� i_fifo_dat ����� � ������� ����� ����
--        * ENDIANNESS = BIG-ENDIAN: �����������
--          ������ �� ���� i_fifo_dat ����� � ������� ����� ����
--    Revision 1.6 (27/02/2015) - Assert �� �������� ENDIANNESS
--
--
-- -----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_func.all;

entity packerx1 is
  generic (
    OWIDTH       : integer := 16; -- �������� �����������
    IMWIDTH      : integer := 64; -- ������������ ����������� ��. ���� ������
    ENDIANNESS   : string  := "LITTLE-ENDIAN" -- "BIG-ENDIAN", "LITTLE-ENDIAN"
  );
  port (
    clk          : in  std_logic;
    sclr         : in  std_logic;

    i_width      : in  std_logic_vector(log2_ceil(IMWIDTH) downto 0); -- ������� �����������

    o_fifo_rden  : out std_logic;
    i_fifo_empty : in  std_logic;
    i_fifo_dat   : in  std_logic_vector(IMWIDTH-1 downto 0);
    i_fifo_str   : in  std_logic;
    i_fifo_end   : in  std_logic;

    o_stb        : out std_logic;
    o_dat        : out std_logic_vector(OWIDTH-1 downto 0);
    o_str        : out std_logic;
    o_end        : out std_logic
  );
end packerx1;

architecture syn of packerx1 is

  -- ���������
  -- ����������� ���� ������ �� �������������� (+1, �.�. ������� ������� �������)
  constant C_ADDR_WIDTH : integer := log2_ceil(IMWIDTH)+1; -- log2_ceil(64) + 1 = 7

  -- ������� ������� �������
  signal reg_sel        : std_logic := '0';
  signal reg_load       : std_logic := '0';
  signal reg_0          : std_logic_vector(IMWIDTH-1 downto 0)   := (others=>'0');
  signal reg_1          : std_logic_vector(IMWIDTH-1 downto 0)   := (others=>'0');
  signal ring_reg       : std_logic_vector(2*IMWIDTH-1 downto 0) := (others=>'0');
  signal ring_reg_inv   : std_logic_vector(2*IMWIDTH-1 downto 0) := (others=>'0');

  -- ����������� �������
  type st_type is (idle, load0, load1, rcv, rcv_wait, rcv_wait_act, flush0, flush1);
  signal state          : st_type   := idle;
  signal fsm_rst        : std_logic := '0';
  signal fsm_fifo_rden  : std_logic := '0';
  signal fsm_addr_ena   : std_logic := '0';
  signal fsm_load_null  : std_logic := '0'; -- ����� ���������� �������� ������� ������
  signal fsm_flush_ena  : std_logic := '0';
  signal fsm_ostart     : std_logic := '0';
  signal fsm_ostart_r   : std_logic := '0';
  signal fsm_oend       : std_logic := '0';

  -- ���� ���������� ������
  type t_regs_arr is array (natural range <>) of std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal addr           : t_regs_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal i_width_r      : std_logic_vector(C_ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal addr_ena       : std_logic := '0';
  signal addr_ena_r     : std_logic := '0';
  signal addr_hop       : std_logic := '0';
  signal addr_hop_r     : std_logic := '0';

  -- �������� ��������������
  signal mux_odat       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mux_odat_inv   : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');

begin

  assert (IMWIDTH = 4 or IMWIDTH = 8 or IMWIDTH = 16 or IMWIDTH = 32 or IMWIDTH = 64)
  report "packerx1: wrong value of parameter 'IMWIDTH'. Read the description!" 
  severity FAILURE;

  assert (ENDIANNESS = "LITTLE-ENDIAN" or ENDIANNESS = "BIG-ENDIAN")
  report "packerx1: wrong value of parameter 'ENDIANNESS'. Read the description!" 
  severity FAILURE;


  --==================================================
  -- ������� ������� �������
  --==================================================
  reg_load <= '1' when ((fsm_fifo_rden = '1' and i_fifo_empty = '0') or fsm_load_null = '1') else '0';

  -- ����� �������� ��� ��������
  regsel_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(fsm_rst = '1')then
            reg_sel <= '0';
        elsif(reg_load = '1')then
            reg_sel <= not reg_sel;
        end if;
    end if;
  end process;

  -- �������� ������ �� ���� ���������
  ringreg_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(reg_load = '1')then
            if(reg_sel = '0')then
                reg_0 <= i_fifo_dat;
            else
                reg_1 <= i_fifo_dat;
            end if;
        end if;
    end if;
  end process;

  -- ������ LITTLE-ENDIAN
  gen_little: if (ENDIANNESS = "LITTLE-ENDIAN") generate
    ring_reg <= reg_1 & reg_0;
    ring_reg_inv <= ring_reg;
    mux_odat_inv <= mux_odat;
  end generate;

  -- ������ BIG-ENDIAN
  gen_big: if (ENDIANNESS = "BIG-ENDIAN") generate

    ring_reg <= reg_0 & reg_1;

    -- �������� �������� � �������� ��� ������� ���������
    reg_inv: for i in 0 to ring_reg'length-1 generate
      ring_reg_inv(i) <= ring_reg(ring_reg'length-1-i);
    end generate;

    -- �������� �������� ��������� ��������������
    mux_inv: for i in 0 to mux_odat'length-1 generate
      mux_odat_inv(i) <= mux_odat(mux_odat'length-1-i);
    end generate;

  end generate;


  --==================================================
  -- ����������� �������
  --==================================================
  fsm_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(sclr = '1')then
            state         <= idle;
            fsm_rst       <= '1';
            fsm_fifo_rden <= '0';
            fsm_addr_ena  <= '0';
            fsm_load_null <= '0';
            fsm_flush_ena <= '0';
            fsm_ostart    <= '0';
            fsm_oend      <= '0';
        else
            case state is
                when idle => -- �������� ���������
                    if(fsm_fifo_rden = '1' and i_fifo_str = '1' and i_fifo_empty = '0')then -- ������ ������ start
                        state <= load0; -- ���������� ������ �������
                    end if;
                    
                    if(i_fifo_empty = '0')then
                        fsm_fifo_rden <= '1';
                    else
                        fsm_fifo_rden <= '0';
                    end if;
                    fsm_rst  <= '0';
                    fsm_oend <= '0';
                    -- fsm_fifo_rden <= '0';
                    -- fsm_addr_ena  <= '0';
                    -- fsm_load_null <= '0';
                    -- fsm_flush_ena <= '0';
                    -- fsm_ostart    <= '0';
                    -- fsm_oend      <= '0';
                    
                --==================================================
                when load0 => -- �������� ��������
                    if(fsm_fifo_rden = '1' and i_fifo_empty = '0')then
                        state         <= load1; -- ���������� ������ �������
                    end if;
                    
                    if(fsm_fifo_rden = '1' and i_fifo_empty = '0')then
                        fsm_fifo_rden <= '0';
                    elsif(i_fifo_empty = '0')then
                        fsm_fifo_rden <= '1';
                    else
                        fsm_fifo_rden <= '0';
                    end if;
                
                --==================================================
                when load1 => -- �������� ��������
                    if(i_fifo_empty = '0')then -- ����� FIFO �� ������
                        state         <= rcv;
                        fsm_addr_ena  <= '1';
                        fsm_ostart    <= '1';
                    end if;
                
                --==================================================
                when rcv => -- ����� � ����������
                    if(fsm_fifo_rden = '1' and i_fifo_end = '1' and i_fifo_empty = '0')then  -- ������ ������ end
                        state         <= flush0;
                        fsm_flush_ena <= '1';
                        if(addr_hop = '1')then
                            fsm_load_null <= '1';
                        end if;
                    elsif(i_fifo_empty = '1')then
                        if(addr_hop_r = '1')then
                            state <= rcv_wait_act;
                        else
                            state <= rcv_wait;
                        end if;
                    end if;
                    
                    if(fsm_fifo_rden = '1' and i_fifo_end = '1' and i_fifo_empty = '0')then
                        fsm_addr_ena <= '0';
                    elsif(i_fifo_empty = '1')then
                        fsm_addr_ena <= '0';
                    end if;
                    
                    if(fsm_fifo_rden = '1' and i_fifo_end = '1' and i_fifo_empty = '0')then
                        fsm_fifo_rden <= '0';
                    elsif(addr_hop = '1' and i_fifo_empty = '0')then
                        fsm_fifo_rden <= '1';
                    else
                        fsm_fifo_rden <= '0';
                    end if;
                    fsm_ostart <= '0';
                    
                --==================================================
                when rcv_wait => -- �������� FIFO
                    if(i_fifo_empty = '0')then
                        state        <= rcv;
                        fsm_addr_ena <= '1';
                    end if;
                
                --==================================================
                -- NOTE: ��� ������ �� ��������� rcv_wait_act
                -- ����� ����� fsm_fifo_rden
                when rcv_wait_act => -- �������� FIFO
                    if(i_fifo_empty = '0')then
                        state         <= rcv;
                        fsm_addr_ena  <= '1';
                        fsm_fifo_rden <= '1';
                    end if;
                
                --==================================================
                when flush0 => -- ������� ��������
                    if(fsm_load_null = '1')then
                        state <= flush1;
                    end if;
                    
                    if(fsm_load_null = '1')then
                        if(addr_hop = '1')then
                            fsm_load_null <= '1';
                        else
                            fsm_load_null <= '0';
                        end if;
                    elsif(addr_hop = '1')then
                        fsm_load_null <= '1';
                    end if;
                    
                --==================================================
                when flush1 => -- ������� ��������
                    if(fsm_load_null = '1')then
                        state         <= idle;
                        fsm_rst       <= '1'; -- ���������� �����
                        fsm_oend      <= '1';
                        fsm_flush_ena <= '0';
                    end if;
                    
                    if(fsm_load_null = '1')then
                        fsm_load_null <= '0';
                    elsif(addr_hop = '1')then
                        fsm_load_null <= '1';
                    end if;
                    
                --==================================================
                when others => NULL;
            end case;
        end if;
    end if;
  end process;

  o_fifo_rden <= fsm_fifo_rden;


  --==================================================
  -- ���� ���������� ������
  -- �� ������ �������� �������������
  -- ���� ����������� ������
  --==================================================
  addr_ena <= '1' when ((fsm_addr_ena = '1' and i_fifo_empty = '0') or fsm_flush_ena = '1') else '0';
  -- addr_ena <= '1' when ((state = rcv and i_fifo_empty = '0') or state = flush0 or state = flush1) else '0';

  addrfrmr_gen: for i in 0 to OWIDTH-1 generate
    u_addrfrmr: entity work.addr_frmr_x1
    GENERIC MAP (
        OPWIDTH => C_ADDR_WIDTH,
        OWIDTH  => OWIDTH,
        INIT    => i)
    PORT MAP (
        clk     => clk,
        rst     => fsm_rst,
        i_ena   => addr_ena,
        i_width => i_width_r,
        o_hop   => open,
        o_addr  => addr(i));
  end generate;

  -- NOTE: ����� ������������ �� ������� �������. �����
  -- ��� ����������� ������� ��������� �������� ��������
  u_addrfrmr: entity work.addr_frmr_x1
  GENERIC MAP (
    OPWIDTH => C_ADDR_WIDTH,
    OWIDTH  => OWIDTH,
    INIT    => OWIDTH)
  PORT MAP (
    clk     => clk,
    rst     => fsm_rst,
    i_ena   => addr_ena,
    i_width => i_width_r,
    o_hop   => addr_hop,
    o_addr  => open);


  --==================================================
  -- �������� ��������������
  -- ������ ������������� ��������
  -- ���� ������ �� �������� ��������
  --==================================================
  mux_gen: for i in 0 to OWIDTH-1 generate
    u_mux: entity work.muxN_1_r
    GENERIC MAP ( 
        ADDRWIDTH => C_ADDR_WIDTH,
        OWIDTH    => IMWIDTH*2)
    PORT MAP (
        clk    => clk,
        addr   => addr(i),
        input  => ring_reg_inv,
        output => mux_odat(i));
  end generate;


  --==================================================
  -- �����
  --==================================================
  del_prc: process(clk)
  begin
    if(rising_edge(clk))then
        i_width_r    <= i_width;
        addr_hop_r   <= addr_hop;
        fsm_ostart_r <= fsm_ostart;
        addr_ena_r   <= addr_ena;
    end if;
  end process;

  o_stb <= addr_ena_r;
  o_dat <= mux_odat_inv;
  o_str <= fsm_ostart_r;
  o_end <= fsm_oend;


end syn;
