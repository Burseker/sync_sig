--================================================================================
-- Description: Модуль коммутации с переходом на AXISteream
-- Version:     0.2.0
-- Developer:   SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    DMA
-- Tools:       modelsim 10.2d
--              
-- Note:
-- 
-- Version History:
-- Ver 0.0.0 - File create
-- Ver 0.1.0 - Первая рабочая версия
-- Ver 0.2.0 - Добавлено еще 4 канала
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=== common lib ===
-- use work.xqpkt_pkg.all;
use work.pkg_func.all;

entity test_commutator_mult_ch is
    generic (
        SIM     : integer := 0
    );
    port (
        aclr            : in  std_logic;    --сброс от SDRAM
        clk             : in  std_logic;
        
        idat_ch0        : in  std_logic_vector(31 downto 0) := (others => '0');
        iend_ch0        : in  std_logic := '0';
        iempty_ch0      : in  std_logic := '1';
        iten_ch0        : out std_logic := '0';
        
        idat_ch1        : in  std_logic_vector(31 downto 0) := (others => '0');
        iend_ch1        : in  std_logic := '0';
        iempty_ch1      : in  std_logic := '1';
        iten_ch1        : out std_logic := '0';
        
        idat_ch2        : in  std_logic_vector(31 downto 0) := (others => '0');
        iend_ch2        : in  std_logic := '0';
        iempty_ch2      : in  std_logic := '1';
        iten_ch2        : out std_logic := '0';
        
        idat_ch3        : in  std_logic_vector(31 downto 0) := (others => '0');
        iend_ch3        : in  std_logic := '0';
        iempty_ch3      : in  std_logic := '1';
        iten_ch3        : out std_logic := '0';
        
        mcomm0_tdata    : out std_logic_vector(31 downto 0);
        mcomm0_tvalid   : out std_logic;
        mcomm0_tlast    : out std_logic;
        mcomm0_tready   : in  std_logic := '1';
        
        mcomm1_tdata    : out std_logic_vector(31 downto 0);
        mcomm1_tvalid   : out std_logic;
        mcomm1_tlast    : out std_logic;
        mcomm1_tready   : in  std_logic := '1';
        
        mcomm2_tdata    : out std_logic_vector(31 downto 0);
        mcomm2_tvalid   : out std_logic;
        mcomm2_tlast    : out std_logic;
        mcomm2_tready   : in  std_logic := '1';
        
        mcomm3_tdata    : out std_logic_vector(31 downto 0);
        mcomm3_tvalid   : out std_logic;
        mcomm3_tlast    : out std_logic;
        mcomm3_tready   : in  std_logic := '1';
        
        mcomm4_tdata    : out std_logic_vector(31 downto 0);
        mcomm4_tvalid   : out std_logic;
        mcomm4_tlast    : out std_logic;
        mcomm4_tready   : in  std_logic := '1';
        
        mcomm5_tdata    : out std_logic_vector(31 downto 0);
        mcomm5_tvalid   : out std_logic;
        mcomm5_tlast    : out std_logic;
        mcomm5_tready   : in  std_logic := '1';
        
        mcomm6_tdata    : out std_logic_vector(31 downto 0);
        mcomm6_tvalid   : out std_logic;
        mcomm6_tlast    : out std_logic;
        mcomm6_tready   : in  std_logic := '1';
        
        mcomm7_tdata    : out std_logic_vector(31 downto 0);
        mcomm7_tvalid   : out std_logic;
        mcomm7_tlast    : out std_logic;
        mcomm7_tready   : in  std_logic := '1';
        
        mcomm8_tdata    : out std_logic_vector(31 downto 0);
        mcomm8_tvalid   : out std_logic;
        mcomm8_tlast    : out std_logic;
        mcomm8_tready   : in  std_logic := '1';
        
        mcomm9_tdata    : out std_logic_vector(31 downto 0);
        mcomm9_tvalid   : out std_logic;
        mcomm9_tlast    : out std_logic;
        mcomm9_tready   : in  std_logic := '1';
        
        mcomm10_tdata    : out std_logic_vector(31 downto 0);
        mcomm10_tvalid   : out std_logic;
        mcomm10_tlast    : out std_logic;
        mcomm10_tready   : in  std_logic := '1';
        
        mcomm11_tdata    : out std_logic_vector(31 downto 0);
        mcomm11_tvalid   : out std_logic;
        mcomm11_tlast    : out std_logic;
        mcomm11_tready   : in  std_logic := '1';
        
        mcomm12_tdata    : out std_logic_vector(31 downto 0);
        mcomm12_tvalid   : out std_logic;
        mcomm12_tlast    : out std_logic;
        mcomm12_tready   : in  std_logic := '1';
        
        mcomm13_tdata    : out std_logic_vector(31 downto 0);
        mcomm13_tvalid   : out std_logic;
        mcomm13_tlast    : out std_logic;
        mcomm13_tready   : in  std_logic := '1';
        
        mcomm14_tdata    : out std_logic_vector(31 downto 0);
        mcomm14_tvalid   : out std_logic;
        mcomm14_tlast    : out std_logic;
        mcomm14_tready   : in  std_logic := '1';
        
        mcomm15_tdata    : out std_logic_vector(31 downto 0);
        mcomm15_tvalid   : out std_logic;
        mcomm15_tlast    : out std_logic;
        mcomm15_tready   : in  std_logic := '1'
    );
end test_commutator_mult_ch;

architecture beh of test_commutator_mult_ch is

    -- type t_dsth_table is array ( 0 to 6 ) of std_logic_vector(7 downto 0);
    -- CONSTANT C_DSTH_TABLE   : t_dsth_table := (x"E0", x"E1",x"E2", x"E4",x"E5", x"E6",x"E7");
    
    
    signal s_mux_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_mux_oend     : std_logic := '0';
    signal s_mux_ostb     : std_logic := '0';
    signal s_mux_oten     : std_logic := '0';
    
    signal s_core_fifo_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_core_fifo_oend     : std_logic := '0';
    signal s_core_fifo_ostb     : std_logic := '0';
    signal s_core_fifo_oten     : std_logic := '0';
    
    signal s_buff0_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff0_oend     : std_logic := '0';
    signal s_buff0_ostb     : std_logic := '0';
    signal s_buff0_oten     : std_logic := '0';
    signal s_buff0_oempty   : std_logic := '0';
    
    signal s_buff1_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff1_oend     : std_logic := '0';
    signal s_buff1_ostb     : std_logic := '0';
    signal s_buff1_oten     : std_logic := '0';
    signal s_buff1_oempty   : std_logic := '0';
    
    signal s_buff2_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff2_oend     : std_logic := '0';
    signal s_buff2_ostb     : std_logic := '0';
    signal s_buff2_oten     : std_logic := '0';
    signal s_buff2_oempty   : std_logic := '0';
    
    signal s_buff3_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff3_oend     : std_logic := '0';
    signal s_buff3_ostb     : std_logic := '0';
    signal s_buff3_oten     : std_logic := '0';
    signal s_buff3_oempty   : std_logic := '0';
    
    signal s_buff4_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff4_oend     : std_logic := '0';
    signal s_buff4_ostb     : std_logic := '0';
    signal s_buff4_oten     : std_logic := '0';
    signal s_buff4_oempty   : std_logic := '0';
    
    signal s_buff5_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff5_oend     : std_logic := '0';
    signal s_buff5_ostb     : std_logic := '0';
    signal s_buff5_oten     : std_logic := '0';
    signal s_buff5_oempty   : std_logic := '0';
    
    signal s_buff6_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff6_oend     : std_logic := '0';
    signal s_buff6_ostb     : std_logic := '0';
    signal s_buff6_oten     : std_logic := '0';
    signal s_buff6_oempty   : std_logic := '0';
    
    signal s_buff7_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff7_oend     : std_logic := '0';
    signal s_buff7_ostb     : std_logic := '0';
    signal s_buff7_oten     : std_logic := '0';
    signal s_buff7_oempty   : std_logic := '0';
    
    signal s_buff8_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff8_oend     : std_logic := '0';
    signal s_buff8_ostb     : std_logic := '0';
    signal s_buff8_oten     : std_logic := '0';
    signal s_buff8_oempty   : std_logic := '0';
    
    signal s_buff9_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff9_oend     : std_logic := '0';
    signal s_buff9_ostb     : std_logic := '0';
    signal s_buff9_oten     : std_logic := '0';
    signal s_buff9_oempty   : std_logic := '0';
    
    signal s_buff10_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff10_oend     : std_logic := '0';
    signal s_buff10_ostb     : std_logic := '0';
    signal s_buff10_oten     : std_logic := '0';
    signal s_buff10_oempty   : std_logic := '0';
    
    signal s_buff11_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff11_oend     : std_logic := '0';
    signal s_buff11_ostb     : std_logic := '0';
    signal s_buff11_oten     : std_logic := '0';
    signal s_buff11_oempty   : std_logic := '0';
    
    signal s_buff12_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff12_oend     : std_logic := '0';
    signal s_buff12_ostb     : std_logic := '0';
    signal s_buff12_oten     : std_logic := '0';
    signal s_buff12_oempty   : std_logic := '0';
    
    signal s_buff13_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff13_oend     : std_logic := '0';
    signal s_buff13_ostb     : std_logic := '0';
    signal s_buff13_oten     : std_logic := '0';
    signal s_buff13_oempty   : std_logic := '0';
    
    signal s_buff14_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff14_oend     : std_logic := '0';
    signal s_buff14_ostb     : std_logic := '0';
    signal s_buff14_oten     : std_logic := '0';
    signal s_buff14_oempty   : std_logic := '0';
    
    signal s_buff15_odata    : std_logic_vector(31 downto 0) := ( others => '0' );
    signal s_buff15_oend     : std_logic := '0';
    signal s_buff15_ostb     : std_logic := '0';
    signal s_buff15_oten     : std_logic := '0';
    signal s_buff15_oempty   : std_logic := '0';
	
    -- -- DEBUG ===============================================
    -- attribute mark_debug : string;
    -- -- Infrastructure
    -- attribute mark_debug of s_cmdrdpkt_fifo_dat     : signal is "TRUE";

    type T_DEMUX_TRD32 is record
        p_dat      : std_logic_vector(31 downto 0);
        p_str      : std_logic;
        p_end      : std_logic;
        p_stb_a    : std_logic;
        p_ten_a    : std_logic;
        p_stb_b    : std_logic;
        p_ten_b    : std_logic;
        p_stb_c    : std_logic;
        p_ten_c    : std_logic;
        p_stb_d    : std_logic;
        p_ten_d    : std_logic;
    end record;
    
    signal s_comm_demux_a  : T_DEMUX_TRD32 := ( (others => '0'), '0', '0',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1');
    signal s_comm_demux_b0  : T_DEMUX_TRD32 := ( (others => '0'), '0', '0',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1');
    signal s_comm_demux_b1  : T_DEMUX_TRD32 := ( (others => '0'), '0', '0',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1');
    signal s_comm_demux_b2  : T_DEMUX_TRD32 := ( (others => '0'), '0', '0',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1');
    signal s_comm_demux_b3  : T_DEMUX_TRD32 := ( (others => '0'), '0', '0',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1',
                                                     '0', '1');
begin
    
    
--=============================================
-- TYPICAL PROCESS
--=============================================
    -- process(aclr, iclk)
    -- begin
        -- if(aclr = '1')then
        -- elsif(rising_edge(iclk))then
        -- end if;
    -- end process;
    
    
--=============================================
-- Мультиплексор
--=============================================
    
qpkt_mux: entity work.qpkt_mux
    generic map(
        WIDTH   => 32,
        CORE_SZ => 4
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat0   => idat_ch0,
        iend0   => iend_ch0,
        iempty0 => iempty_ch0,
        iten0   => iten_ch0,
        
        idat1   => idat_ch1,
        iend1   => iend_ch1,
        iempty1 => iempty_ch1,
        iten1   => iten_ch1,
        
        idat2   => idat_ch2,
        iend2   => iend_ch2,
        iempty2 => iempty_ch2,
        iten2   => iten_ch2,
        
        idat3   => idat_ch3,
        iend3   => iend_ch3,
        iempty3 => iempty_ch3,
        iten3   => iten_ch3,
        
        odat    => s_mux_odata,
        ostb    => s_mux_ostb,
        oend    => s_mux_oend,
        oempty  => open,
        oten    => s_mux_oten
    );
    
 
    core_fifo: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_mux_odata,
        iend    => s_mux_oend,
        istb    => s_mux_ostb,
		iten    => s_mux_oten,
        
		odat    => s_core_fifo_odata,
		oend    => s_core_fifo_oend,
		ostb    => s_core_fifo_ostb,
		oten    => s_core_fifo_oten
	);
    
    
--=============================================
-- Демультиплексоры
--=============================================
   
    qpkt_demux_a: entity work.qpkt_demux
    generic map(
        WIDTH   => 32,
        addr0   => x"E4",
        addr1   => x"E8",
        addr2   => x"F2"
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat    => s_core_fifo_odata,
        istb    => s_core_fifo_ostb,
        iend    => s_core_fifo_oend,
        iten    => s_core_fifo_oten,
        
        odat    => s_comm_demux_a.p_dat,
        oend    => s_comm_demux_a.p_end,
        ostr    => s_comm_demux_a.p_str,
        
        ostb0   => s_comm_demux_a.p_stb_a,
        oten0   => s_comm_demux_a.p_ten_a,
        
        ostb1   => s_comm_demux_a.p_stb_b,
        oten1   => s_comm_demux_a.p_ten_b,
        
        ostb2   => s_comm_demux_a.p_stb_c,
        oten2   => s_comm_demux_a.p_ten_c,
        
        ostb3   => s_comm_demux_a.p_stb_d,
        oten3   => s_comm_demux_a.p_ten_d
    );
    
    
    qpkt_demux_b0: entity work.qpkt_demux
    generic map(
        WIDTH   => 32,
        addr0   => x"E1",
        addr1   => x"E2",
        addr2   => x"E3"
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat    => s_comm_demux_a.p_dat,
        istb    => s_comm_demux_a.p_stb_a,
        iend    => s_comm_demux_a.p_end,
        iten    => s_comm_demux_a.p_ten_a,
        
        odat    => s_comm_demux_b0.p_dat,
        oend    => s_comm_demux_b0.p_end,
        ostr    => s_comm_demux_b0.p_str,
        
        ostb0   => s_comm_demux_b0.p_stb_a,
        oten0   => s_comm_demux_b0.p_ten_a,
        
        ostb1   => s_comm_demux_b0.p_stb_b,
        oten1   => s_comm_demux_b0.p_ten_b,
        
        ostb2   => s_comm_demux_b0.p_stb_c,
        oten2   => s_comm_demux_b0.p_ten_c,
        
        ostb3   => s_comm_demux_b0.p_stb_d,
        oten3   => s_comm_demux_b0.p_ten_d
    );
    
    
    qpkt_demux_b1: entity work.qpkt_demux
    generic map(
        WIDTH   => 32,
        addr0   => x"E5",
        addr1   => x"E6",
        addr2   => x"E7"
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat    => s_comm_demux_a.p_dat,
        istb    => s_comm_demux_a.p_stb_b,
        iend    => s_comm_demux_a.p_end,
        iten    => s_comm_demux_a.p_ten_b,
        
        odat    => s_comm_demux_b1.p_dat,
        oend    => s_comm_demux_b1.p_end,
        ostr    => s_comm_demux_b1.p_str,
        
        ostb0   => s_comm_demux_b1.p_stb_a,
        oten0   => s_comm_demux_b1.p_ten_a,
        
        ostb1   => s_comm_demux_b1.p_stb_b,
        oten1   => s_comm_demux_b1.p_ten_b,
        
        ostb2   => s_comm_demux_b1.p_stb_c,
        oten2   => s_comm_demux_b1.p_ten_c,
        
        ostb3   => s_comm_demux_b1.p_stb_d,
        oten3   => s_comm_demux_b1.p_ten_d
    );
    
    
    qpkt_demux_b2: entity work.qpkt_demux
    generic map(
        WIDTH   => 32,
        addr0   => x"E9",
        addr1   => x"F0",
        addr2   => x"F1"
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat    => s_comm_demux_a.p_dat,
        istb    => s_comm_demux_a.p_stb_c,
        iend    => s_comm_demux_a.p_end,
        iten    => s_comm_demux_a.p_ten_c,
        
        odat    => s_comm_demux_b2.p_dat,
        oend    => s_comm_demux_b2.p_end,
        ostr    => s_comm_demux_b2.p_str,
        
        ostb0   => s_comm_demux_b2.p_stb_a,
        oten0   => s_comm_demux_b2.p_ten_a,
        
        ostb1   => s_comm_demux_b2.p_stb_b,
        oten1   => s_comm_demux_b2.p_ten_b,
        
        ostb2   => s_comm_demux_b2.p_stb_c,
        oten2   => s_comm_demux_b2.p_ten_c,
        
        ostb3   => s_comm_demux_b2.p_stb_d,
        oten3   => s_comm_demux_b2.p_ten_d
    );
    
    
    qpkt_demux_b3: entity work.qpkt_demux
    generic map(
        WIDTH   => 32,
        addr0   => x"F3",
        addr1   => x"F4",
        addr2   => x"F5"
    )
    port map(	
        aclr    => aclr,
        clk     => clk,
        
        idat    => s_comm_demux_a.p_dat,
        istb    => s_comm_demux_a.p_stb_d,
        iend    => s_comm_demux_a.p_end,
        iten    => s_comm_demux_a.p_ten_d,
        
        odat    => s_comm_demux_b3.p_dat,
        oend    => s_comm_demux_b3.p_end,
        ostr    => s_comm_demux_b3.p_str,
        
        ostb0   => s_comm_demux_b3.p_stb_a,
        oten0   => s_comm_demux_b3.p_ten_a,
        
        ostb1   => s_comm_demux_b3.p_stb_b,
        oten1   => s_comm_demux_b3.p_ten_b,
        
        ostb2   => s_comm_demux_b3.p_stb_c,
        oten2   => s_comm_demux_b3.p_ten_c,
        
        ostb3   => s_comm_demux_b3.p_stb_d,
        oten3   => s_comm_demux_b3.p_ten_d
    );
    
    
--=============================================
-- Выходные FIFO GR0
--=============================================


    qpkt_scfifo_ch0: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b0.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b0.p_end,
        istb    => s_comm_demux_b0.p_stb_a,
		iten    => s_comm_demux_b0.p_ten_a,
        
		odat    => s_buff0_odata,
		-- ostr    : out std_logic;
		oend    => s_buff0_oend,
		ostb    => s_buff0_ostb,
		oten    => s_buff0_oten,
		oempty  => s_buff0_oempty
	);
    
    
    qpkt_scfifo_ch1: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b0.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b0.p_end,
        istb    => s_comm_demux_b0.p_stb_b,
		iten    => s_comm_demux_b0.p_ten_b,
        
		odat    => s_buff1_odata,
		-- ostr    : out std_logic;
		oend    => s_buff1_oend,
		ostb    => s_buff1_ostb,
		oten    => s_buff1_oten,
		oempty  => s_buff1_oempty
	);
    
    
    qpkt_scfifo_ch2: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b0.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b0.p_end,
        istb    => s_comm_demux_b0.p_stb_c,
		iten    => s_comm_demux_b0.p_ten_c,
        
		odat    => s_buff2_odata,
		-- ostr    : out std_logic;
		oend    => s_buff2_oend,
		ostb    => s_buff2_ostb,
		oten    => s_buff2_oten,
		oempty  => s_buff2_oempty
	);
    
    
    qpkt_scfifo_ch3: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b0.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b0.p_end,
        istb    => s_comm_demux_b0.p_stb_d,
		iten    => s_comm_demux_b0.p_ten_d,
        
		odat    => s_buff3_odata,
		-- ostr    : out std_logic;
		oend    => s_buff3_oend,
		ostb    => s_buff3_ostb,
		oten    => s_buff3_oten,
		oempty  => s_buff3_oempty
	);
    
    
--=============================================
-- Выходные FIFO GR1
--=============================================


    qpkt_scfifo_ch4: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b1.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b1.p_end,
        istb    => s_comm_demux_b1.p_stb_a,
		iten    => s_comm_demux_b1.p_ten_a,
        
		odat    => s_buff4_odata,
		-- ostr    : out std_logic;
		oend    => s_buff4_oend,
		ostb    => s_buff4_ostb,
		oten    => s_buff4_oten,
		oempty  => s_buff4_oempty
	);
    
    
    qpkt_scfifo_ch5: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b1.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b1.p_end,
        istb    => s_comm_demux_b1.p_stb_b,
		iten    => s_comm_demux_b1.p_ten_b,
        
		odat    => s_buff5_odata,
		-- ostr    : out std_logic;
		oend    => s_buff5_oend,
		ostb    => s_buff5_ostb,
		oten    => s_buff5_oten,
		oempty  => s_buff5_oempty
	);
    
    
    qpkt_scfifo_ch6: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b1.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b1.p_end,
        istb    => s_comm_demux_b1.p_stb_c,
		iten    => s_comm_demux_b1.p_ten_c,
        
		odat    => s_buff6_odata,
		-- ostr    : out std_logic;
		oend    => s_buff6_oend,
		ostb    => s_buff6_ostb,
		oten    => s_buff6_oten,
		oempty  => s_buff6_oempty
	);
    
    
    qpkt_scfifo_ch7: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b1.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b1.p_end,
        istb    => s_comm_demux_b1.p_stb_d,
		iten    => s_comm_demux_b1.p_ten_d,
        
		odat    => s_buff7_odata,
		-- ostr    : out std_logic;
		oend    => s_buff7_oend,
		ostb    => s_buff7_ostb,
		oten    => s_buff7_oten,
		oempty  => s_buff7_oempty
	);
    
--=============================================
-- Выходные FIFO GR2
--=============================================


    qpkt_scfifo_ch8: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b2.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b2.p_end,
        istb    => s_comm_demux_b2.p_stb_a,
		iten    => s_comm_demux_b2.p_ten_a,
        
		odat    => s_buff8_odata,
		-- ostr    : out std_logic;
		oend    => s_buff8_oend,
		ostb    => s_buff8_ostb,
		oten    => s_buff8_oten,
		oempty  => s_buff8_oempty
	);
    
    
    qpkt_scfifo_ch9: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b2.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b2.p_end,
        istb    => s_comm_demux_b2.p_stb_b,
		iten    => s_comm_demux_b2.p_ten_b,
        
		odat    => s_buff9_odata,
		-- ostr    : out std_logic;
		oend    => s_buff9_oend,
		ostb    => s_buff9_ostb,
		oten    => s_buff9_oten,
		oempty  => s_buff9_oempty
	);
    
    
    qpkt_scfifo_ch10: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b2.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b2.p_end,
        istb    => s_comm_demux_b2.p_stb_c,
		iten    => s_comm_demux_b2.p_ten_c,
        
		odat    => s_buff10_odata,
		-- ostr    : out std_logic;
		oend    => s_buff10_oend,
		ostb    => s_buff10_ostb,
		oten    => s_buff10_oten,
		oempty  => s_buff10_oempty
	);
    
    
    qpkt_scfifo_ch11: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b2.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b2.p_end,
        istb    => s_comm_demux_b2.p_stb_d,
		iten    => s_comm_demux_b2.p_ten_d,
        
		odat    => s_buff11_odata,
		-- ostr    : out std_logic;
		oend    => s_buff11_oend,
		ostb    => s_buff11_ostb,
		oten    => s_buff11_oten,
		oempty  => s_buff11_oempty
	);
    
    
    qpkt_scfifo_ch12: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b3.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b3.p_end,
        istb    => s_comm_demux_b3.p_stb_a,
		iten    => s_comm_demux_b3.p_ten_a,
        
		odat    => s_buff12_odata,
		-- ostr    : out std_logic;
		oend    => s_buff12_oend,
		ostb    => s_buff12_ostb,
		oten    => s_buff12_oten,
		oempty  => s_buff12_oempty
	);
    
    
    qpkt_scfifo_ch13: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b3.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b3.p_end,
        istb    => s_comm_demux_b3.p_stb_b,
		iten    => s_comm_demux_b3.p_ten_b,
        
		odat    => s_buff13_odata,
		-- ostr    : out std_logic;
		oend    => s_buff13_oend,
		ostb    => s_buff13_ostb,
		oten    => s_buff13_oten,
		oempty  => s_buff13_oempty
	);
    
    
    qpkt_scfifo_ch14: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b3.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b3.p_end,
        istb    => s_comm_demux_b3.p_stb_c,
		iten    => s_comm_demux_b3.p_ten_c,
        
		odat    => s_buff14_odata,
		-- ostr    : out std_logic;
		oend    => s_buff14_oend,
		ostb    => s_buff14_ostb,
		oten    => s_buff14_oten,
		oempty  => s_buff14_oempty
	);
    
    
    qpkt_scfifo_ch15: entity work.qpkt_scfifo
    generic map(
        WIDTH    => 32,
        DEPTH    => 64,
        AFULL_TR => 48
    )
	port map(
		aclr    => aclr,
		clk     => clk,
        
		idat    => s_comm_demux_b3.p_dat,
        -- istr    : in  std_logic;
        iend    => s_comm_demux_b3.p_end,
        istb    => s_comm_demux_b3.p_stb_d,
		iten    => s_comm_demux_b3.p_ten_d,
        
		odat    => s_buff15_odata,
		-- ostr    : out std_logic;
		oend    => s_buff15_oend,
		ostb    => s_buff15_ostb,
		oten    => s_buff15_oten,
		oempty  => s_buff15_oempty
	);
    
    
--=============================================
--          SIGNALS ASSYGMENTS
--=============================================
    mcomm0_tdata  <= s_buff0_odata;
    mcomm0_tlast  <= s_buff0_oend;
    mcomm0_tvalid <= not s_buff0_oempty;
    s_buff0_oten <= mcomm0_tready;
    
    mcomm1_tdata  <= s_buff1_odata;
    mcomm1_tlast  <= s_buff1_oend;
    mcomm1_tvalid <= not s_buff1_oempty;
    s_buff1_oten <= mcomm1_tready;
    
    mcomm2_tdata  <= s_buff2_odata;
    mcomm2_tlast  <= s_buff2_oend;
    mcomm2_tvalid <= not s_buff2_oempty;
    s_buff2_oten <= mcomm2_tready;
    
    mcomm3_tdata  <= s_buff3_odata;
    mcomm3_tlast  <= s_buff3_oend;
    mcomm3_tvalid <= not s_buff3_oempty;
    s_buff3_oten <= mcomm3_tready;


    mcomm4_tdata  <= s_buff4_odata;
    mcomm4_tlast  <= s_buff4_oend;
    mcomm4_tvalid <= not s_buff4_oempty;
    s_buff4_oten <= mcomm4_tready;
    
    mcomm5_tdata  <= s_buff5_odata;
    mcomm5_tlast  <= s_buff5_oend;
    mcomm5_tvalid <= not s_buff5_oempty;
    s_buff5_oten <= mcomm5_tready;
    
    mcomm6_tdata  <= s_buff6_odata;
    mcomm6_tlast  <= s_buff6_oend;
    mcomm6_tvalid <= not s_buff6_oempty;
    s_buff6_oten <= mcomm6_tready;
    
    mcomm7_tdata  <= s_buff7_odata;
    mcomm7_tlast  <= s_buff7_oend;
    mcomm7_tvalid <= not s_buff7_oempty;
    s_buff7_oten <= mcomm7_tready;


    mcomm8_tdata  <= s_buff8_odata;
    mcomm8_tlast  <= s_buff8_oend;
    mcomm8_tvalid <= not s_buff8_oempty;
    s_buff8_oten <= mcomm8_tready;
    
    mcomm9_tdata  <= s_buff9_odata;
    mcomm9_tlast  <= s_buff9_oend;
    mcomm9_tvalid <= not s_buff9_oempty;
    s_buff9_oten <= mcomm9_tready;
    
    mcomm10_tdata  <= s_buff10_odata;
    mcomm10_tlast  <= s_buff10_oend;
    mcomm10_tvalid <= not s_buff10_oempty;
    s_buff10_oten <= mcomm10_tready;
    
    mcomm11_tdata  <= s_buff11_odata;
    mcomm11_tlast  <= s_buff11_oend;
    mcomm11_tvalid <= not s_buff11_oempty;
    s_buff11_oten <= mcomm11_tready;

    mcomm12_tdata  <= s_buff12_odata;
    mcomm12_tlast  <= s_buff12_oend;
    mcomm12_tvalid <= not s_buff12_oempty;
    s_buff12_oten <= mcomm12_tready;
    
    mcomm13_tdata  <= s_buff13_odata;
    mcomm13_tlast  <= s_buff13_oend;
    mcomm13_tvalid <= not s_buff13_oempty;
    s_buff13_oten <= mcomm13_tready;
    
    mcomm14_tdata  <= s_buff14_odata;
    mcomm14_tlast  <= s_buff14_oend;
    mcomm14_tvalid <= not s_buff14_oempty;
    s_buff14_oten <= mcomm14_tready;
    
    mcomm15_tdata  <= s_buff15_odata;
    mcomm15_tlast  <= s_buff15_oend;
    mcomm15_tvalid <= not s_buff15_oempty;
    s_buff15_oten <= mcomm15_tready;

end beh;
