-- =============================================================================
-- Description: packerx1 multiplexer
-- Version:     1.0
-- Designer:    SVB
-- Workgroup:   IRS
-- =============================================================================
-- Keywords:    Packer, Multiplexer
-- Tools:       Altera Quartus II 9.1
--
-- Dependencies:
--
-- Details:
-- muxN_1_r - мультиплексор N:1 с регистровым выходом
--
-- Version History:
-- Ver 1.0 - (ARP: 24.10.2014) Первая версия
--
-- -----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity muxN_1_r is
  generic (
    ADDRWIDTH : natural := 6;
    OWIDTH    : natural := 128
  );
  port (
    clk    : in  std_logic;
    addr   : in  std_logic_vector(ADDRWIDTH-1 downto 0);
    input  : in  std_logic_vector(OWIDTH-1 downto 0);
    output : out std_logic
  );
end muxN_1_r;

architecture syn of muxN_1_r is

  signal int_addr : integer range 0 to 2**ADDRWIDTH-1 := 0;

begin

  int_addr <= to_integer(unsigned(addr));

  mux_prc: process(clk)
  begin
    if(rising_edge(clk))then
        output <= input(int_addr);
    end if;
  end process;

end syn;
