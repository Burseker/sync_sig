--*****************************************************************************
--Author: Ryabkov Andrey
--Vendor: 
--Version: 1.2
--Application: 
--Filename: packer1x.vhd
--Date Last Modified: 
--Date Created: 
--
--Device: Stratix-II, Virtex-5, Spartan-6
--Design Name: �������
--Purpose:    packer1x - ������ ���������
--        * ����������� ������� ���� ����� ��������
--          � �������� ������, ���� i_width
--        * ����������� �������� ���� �������� ���
--          ����������, �������� OWIDTH
--
--Dependencies:
--        * ��������� OWIDTH = 32
--        * ��� ��� ���� �������� ����������� ����, �� i_width
--          ������ ���� ������ ������ ��� ����� OWIDTH
--        * ����� ����� i_width ���� ������� ������ sclr
--        * ������ ������������ ��������� ������ i_start � i_end,
--          ����� ������� ����� �������� �����������. �����
--          ����� �������� ������ ���� ����������
--        * ���������� ��������� ���������� o_rdy - ����
--          ����� ��������� ������ - ������ i_start, i_stb
--        * ���� i_width ������ OWIDTH, �� ������� �����
--          ������ ���� ��������� � ������� �������� i_dat
--
--Reference:
--
--Revision History:
--    Revision 0.1.0 (29/09/2011) - ������ ������
--        * �� ����� ������ ������������� ��������� IMWIDTH
--    Revision 0.1.1 (29/09/2011) - ���� ������������
--        * ���� ������������ flex_packer -> packer1x
--        * ���������� ������ �������� � flush. �� ������, ���
--          ���� i_end_r = '1' and addr_hop = '1', �������� �����
--          �� ����������� ����������� ���������.
--          ����� �������� ��� i_width = 1, 2, 4, 8, 16, 32
--        * ������ ����������. ��� ����� ������ ������ addr_align
--          ����� addr_frmr. ���� addr_hop = '1' and addr_align = '1',
--          �������� ����� ����������� ���������
--        * �������� ������� ������ oend, ������� oend_prc
--        * �������� ������� ��������� ������� fsm_flush �
--          ��������� receive
--    Revision 0.1.2 (10/10/2014) - ������������ ����������� ������
--        * addr_frmr -> addr_frmr_1x
--
--
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_packer1x.all;

entity packer1x is
  generic (
    OWIDTH  : integer := 32; -- �������� �����������
    IMWIDTH : integer := 32  -- ������������ ����������� ��. ���� ������
  );
  port (
    clk     : in  std_logic;
    sclr    : in  std_logic;
    
    i_stb   : in  std_logic;
    i_dat   : in  std_logic_vector(OWIDTH-1 downto 0);
    i_start : in  std_logic;
    i_end   : in  std_logic;
    i_width : in  std_logic_vector(log2_ceil(OWIDTH) downto 0); -- log2_ceil(32) = 5
    o_rdy   : out std_logic; -- ���������� ��������� ������
    
    o_stb   : out std_logic;
    o_dat   : out std_logic_vector(OWIDTH-1 downto 0);
    o_start : out std_logic;
    o_end   : out std_logic
  );
end packer1x;

architecture syn of packer1x is

  -- ���������
  -- ����������� ������, ������������ addr_frmr (+1, �.�. �������� ������� �������)
  constant c_addr_w     : integer := log2_ceil(OWIDTH)+1; -- log2_ceil(32) + 1 = 6
  -- ����������� ������, ������������ addr_dc
  constant c_dc_oaddr_w : integer := OWIDTH;
  -- ����������� ������, ������������ addr_cd
  constant c_cd_oaddr_w : integer := c_addr_w-1;
  
  -- �������
  -- ���������� ���������� �����
  signal reset          : std_logic := '0';
  
  -- ����������� �������
  type st_type is (idle, start, receive, flush);
  signal state          : st_type := idle;
  signal fsm_reset      : std_logic := '0';
  signal fsm_ostart     : std_logic := '0';
  signal fsm_flush      : std_logic := '0';
  signal fsm_flush_r    : std_logic := '0';
  signal fsm_rdy        : std_logic := '0';

  -- �������� ������ � �������
  signal i_dat_r        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal i_dat_r1       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal i_dat_r2       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal i_dat_inv      : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal istrobe        : std_logic := '0';
  signal i_end_r        : std_logic := '0';
  
  -- ���� ���������� ������
  type t_addr_arr is array (natural range <>) of std_logic_vector(c_addr_w-1 downto 0);
  signal addr           : t_addr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal addr_align     : std_logic := '0';
  signal addr_hop       : std_logic := '0';
  signal addr_hop_r     : std_logic := '0';
  signal addr_hop_r1    : std_logic := '0';
  signal addr_hop_r2    : std_logic := '0';
  signal addr_hop_r3    : std_logic := '0';
  signal addr_hop_r4    : std_logic := '0';
  signal addr_hop_r5    : std_logic := '0';
  
  -- �����������
  type t_dcaddr_arr is array (natural range <>) of std_logic_vector(c_dc_oaddr_w-1 downto 0);
  signal dc_oaddr       : t_dcaddr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal s_iwidth       : integer range 0 to OWIDTH := 0;
  signal dc_ena         : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal dc_ohigh       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  -- ���������
  type t_cdaddr_arr is array (natural range <>) of std_logic_vector(c_cd_oaddr_w-1 downto 0);
  signal cd_oaddr       : t_cdaddr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal cd_iaddr       : t_dcaddr_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal cd_istb        : std_logic := '0';
  signal cd_ostb        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal cd_ohigh       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  -- ��������������
  signal mx_idat        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mx_odat        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mx_ostb        : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  signal mx_ohigh       : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');
  
  -- ����������������
  type t_stb_arr is array (natural range <>) of std_logic_vector(1 downto 0);
  type t_dat_arr is array (natural range <>) of std_logic_vector(1 downto 0);
  signal dmxostb        : t_stb_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal dmxodat        : t_dat_arr(0 to OWIDTH-1) := (others=>(others=>'0'));
  signal dmx_ostb       : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  signal dmx_odat       : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  
  -- �������� ������� �������
  signal oreg           : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  signal oreg_inv       : std_logic_vector(2*OWIDTH-1 downto 0) := (others=>'0');
  signal reg_sel        : std_logic := '0';
  
  -- �����
  signal ostb           : std_logic := '0';
  signal oend           : std_logic := '0';
  signal oend_r         : std_logic := '0';
  signal oend_r1        : std_logic := '0';
  signal oend_r2        : std_logic := '0';
  signal oend_r3        : std_logic := '0';
  signal oend_r4        : std_logic := '0';
  signal oend_r5        : std_logic := '0';
  signal odat           : std_logic_vector(OWIDTH-1 downto 0) := (others=>'0');

begin
  
  --==================================================
  -- ���������� ���������� �����
  --==================================================
  reset_prc: process(clk)
  begin
    if(rising_edge(clk))then
        reset <= sclr or fsm_reset;
    end if;
  end process;
  
  
  --==================================================
  -- ����������� �������
  --==================================================
  fsm_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(sclr = '1')then
            state <= idle;
            fsm_reset  <= '1';
            fsm_ostart <= '0';
            fsm_flush  <= '0';
            fsm_rdy    <= '0';
        else
            case state is
                when idle => -- �������� ���������
                    if(i_start = '1')then
                        state <= start;
                    end if;
                    fsm_reset <= '0';
                    fsm_rdy   <= '1';
                    
                --==================================================
                when start => -- �������� ������ o_start
                    if(addr_hop_r5 = '1')then
                        state <= receive;
                        fsm_ostart <= '1';
                    end if;
                    
                --==================================================
                -- NOTE: ���� i_end_r = '1' and addr_hop = '1' and addr_align = '1',
                -- �� �������� ����� ����������� ���������. ����� �����������
                -- ������ ������������ ��� ��������� �����, ����� ���������� (fsm_flush)
                when receive => -- ����� � ��������
                    if(i_end_r = '1')then
                        state <= flush;
                        if(addr_hop = '1' and addr_align = '1')then
                            fsm_flush <= '0'; -- ��������� ������� �� �����
                        else
                            fsm_flush <= '1'; -- ����� ����� ��������� �������
                        end if;
                    end if;
                    if(i_end = '1')then
                        fsm_rdy <= '0';
                    end if;
                    fsm_ostart <= '0';
                    
                --==================================================
                when flush => -- ��������� �������� �������
                    if(oend_r4 = '1')then
                        state <= idle;
                        fsm_reset <= '1';
                    end if;
                    if(addr_hop = '1')then
                        fsm_flush <= '0';
                    end if;
                    
                --==================================================
                when others => NULL;
            end case;
        end if;
    end if;
  end process;


  --==================================================
  -- �������� ������ � �������
  --==================================================
  -- �������� �������� �������� ����� ��� ������� ���������
  reg_inv: for i in 0 to OWIDTH-1 generate
    i_dat_inv(i) <= i_dat(OWIDTH-1-i);
  end generate;
  
  del_prc: process(clk)
  begin
    if(rising_edge(clk))then
        -- ������� �����
        istrobe  <= i_stb or fsm_flush;
        -- ����� �� �����������
        cd_istb  <= istrobe;
        -- ����������� ������ �� �������������
        i_dat_r  <= i_dat_inv;
        i_dat_r1 <= i_dat_r;
        i_dat_r2 <= i_dat_r1;
        mx_idat  <= i_dat_r2;
        -- ����������� ������� ����
        s_iwidth <= to_integer(unsigned(i_width));
    end if;
  end process;

  --==================================================
  -- ����� o_end
  oend_prc: process(clk)
  begin
    if(rising_edge(clk))then
        -- �������� ������ i_end �� 1 ����
        i_end_r <= i_end;
        -- ����� oend
        -- if(addr_hop = '1' and (i_end_r = '1' or fsm_flush = '1'))then
        -- if(addr_hop = '1' and (i_end_r = '1' or (istrobe = '1' and state = flush)))then
        fsm_flush_r <= fsm_flush;
        -- if(addr_hop = '1' and (i_end_r = '1' or fsm_flush_r = '1'))then
        if(addr_hop = '1' and ((i_end_r = '1' and addr_align = '1') or fsm_flush_r = '1'))then
            oend <= '1';
        else
            oend <= '0';
        end if;
        -- �������� ������ oend
        oend_r  <= oend;
        oend_r1 <= oend_r;
        oend_r2 <= oend_r1;
        oend_r3 <= oend_r2;
        oend_r4 <= oend_r3;
        oend_r5 <= oend_r4;
    end if;
  end process;
  

  --==================================================
  -- ���� ���������� ������
  -- ���������� ������� ��������� ��������, � �������
  -- ����� �������� ����������� ������� �����
  --==================================================
  -- ������� addr_frmr
  -- NOTE: addr_hop ������� � ������ �������� addr_frmr
  u_addrfrmr: addr_frmr_1x
  GENERIC MAP(
    OPWIDTH => c_addr_w,
    OWIDTH  => OWIDTH,
    INIT    => 0)
  PORT MAP(
    clk     => clk,
    sclr    => reset,
    i_ena   => istrobe,
    i_width => i_width,
    o_hop   => addr_hop,
    o_align => addr_align,
    o_addr  => addr(0));
  
  -- ��������� addr_frmr
  addr_gen: for i in 1 to OWIDTH-1 generate
    u_addrfrmr: addr_frmr_1x
    GENERIC MAP(
        OPWIDTH => c_addr_w,
        OWIDTH  => OWIDTH,
        INIT    => i)
    PORT MAP(
        clk     => clk,
        sclr    => reset,
        i_ena   => istrobe,
        i_width => i_width,
        o_hop   => open,
        o_align => open,
        o_addr  => addr(i));
  end generate;
  
  -- ����� - ������ � ��������� �������� �������
  ohop_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(istrobe = '1')then
            addr_hop_r <= addr_hop;
        else
            addr_hop_r <= '0';
        end if;
        addr_hop_r1 <= addr_hop_r;
        addr_hop_r2 <= addr_hop_r1;
        addr_hop_r3 <= addr_hop_r2;
        addr_hop_r4 <= addr_hop_r3;
        addr_hop_r5 <= addr_hop_r4;
    end if;
  end process;
  
  
  --==================================================
  -- ����� ������� ������������
  --==================================================
  dcena_gen: for i in 0 to OWIDTH-1 generate
    dcena_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(s_iwidth > i)then
                dc_ena(i) <= '1';
            else
                dc_ena(i) <= '0';
            end if;
        end if;
    end process;
  end generate;
  
  
  --==================================================
  -- �����������
  -- ������� ������ �� �������. ����� ��������� ��������
  -- �������� �������������� �� ��������� ������� (o_high)
  --==================================================
  dc_gen: for i in 0 to OWIDTH-1 generate
    u_addrdc: addr_dc
    GENERIC MAP(
        OWIDTH => OWIDTH)
    PORT MAP(
        clk    => clk,
        i_stb  => istrobe,
        i_ena  => dc_ena(i),
        i_addr => addr(i),
        o_high => dc_ohigh(i),
        o_addr => dc_oaddr(i));
  end generate;
  
  
  --==================================================
  -- ���������
  --==================================================
  -- ������� ����� �� ���������
  cd_iaddr_gen_i: for i in 0 to OWIDTH-1 generate
    cd_iaddr_gen_j: for j in 0 to OWIDTH-1 generate
        cd_iaddr(j)(i) <= dc_oaddr(i)(j);
    end generate;
  end generate;

  -- ���������
  cd_gen: for i in 0 to OWIDTH-1 generate
    u_addrcd: addr_cd
    GENERIC MAP(
        OWIDTH => OWIDTH)
    PORT MAP(
        clk    => clk,
        i_stb  => cd_istb,
        i_high => dc_ohigh,
        i_addr => cd_iaddr(i),
        o_stb  => cd_ostb(i),
        o_high => cd_ohigh(i),
        o_addr => cd_oaddr(i));
  end generate;


  --==================================================
  -- ��������������
  --==================================================
  mx_gen: for i in 0 to OWIDTH-1 generate
    ow32_gen: if (OWIDTH = 32) generate
        u_mux32_1: mux32_1_r
        PORT MAP(
            clk    => clk,
            addr   => cd_oaddr(i),
            input  => mx_idat,
            output => mx_odat(i));
    end generate;
  end generate;
  
  mxout_prc: process(clk)
  begin
    if(rising_edge(clk))then
        mx_ohigh <= cd_ohigh;
        mx_ostb  <= cd_ostb;
    end if;
  end process;
  
  
  --==================================================
  -- ����������������
  --==================================================
  dmux_gen: for i in 0 to OWIDTH-1 generate
    u_dmux1_2: dmux1_2_r
    PORT MAP(
        clk    => clk,
        i_stb  => mx_ostb(i),
        i_addr => mx_ohigh(i),
        i_dat  => mx_odat(i),
        o_stb  => dmxostb(i),
        o_dat  => dmxodat(i));
  end generate;
  
  dmxout_gen: for i in 0 to OWIDTH-1 generate
    dmx_ostb(i)        <= dmxostb(i)(0);
    dmx_ostb(i+OWIDTH) <= dmxostb(i)(1);
    dmx_odat(i)        <= dmxodat(i)(0);
    dmx_odat(i+OWIDTH) <= dmxodat(i)(1);
  end generate;
  
  
  --==================================================
  -- �������� ������� �������
  -- ������� ������� ����� ��� �������������
  -- �������� �������� ������� ����
  --==================================================
  -- �������� �������
  oreg_i_gen: for i in 0 to 2*OWIDTH-1 generate
    oreg_i_prc: process(clk)
    begin
        if(rising_edge(clk))then
            if(dmx_ostb(i) = '1')then
                oreg(i) <= dmx_odat(i);
            end if;
        end if;
    end process;
  end generate;
  
  -- �������� ��������
  oreg_inv_gen: for i in 0 to 2*OWIDTH-1 generate
    oreg_inv(i) <= oreg(2*OWIDTH-1-i);
  end generate;
  
  -- ����� �������� ��� ������
  regsel_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(reset = '1')then
            reg_sel <= '0';
        elsif(addr_hop_r4 = '1')then
            reg_sel <= not reg_sel;
        end if;
    end if;
  end process;
  
  -- �����
  oreg_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(addr_hop_r5 = '1')then
            ostb <= '1';
        else
            ostb <= '0';
        end if;
    end if;
  end process;
  
  -- �������� �������������
  odat_prc: process(clk)
  begin
    if(rising_edge(clk))then
        if(reg_sel = '0')then
            odat <= oreg_inv(OWIDTH-1 downto 0);
        else
            odat <= oreg_inv(2*OWIDTH-1 downto OWIDTH);
        end if;
    end if;
  end process;
  
  
  --==================================================
  -- �����
  --==================================================
  o_rdy   <= fsm_rdy and not i_end;
  o_stb   <= ostb;
  o_dat   <= odat;
  o_start <= fsm_ostart;
  o_end   <= oend_r5;


end syn;
