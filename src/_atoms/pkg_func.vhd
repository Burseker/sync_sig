--================================================================================
-- Description: Пакет популярных функций
-- Version:     1.4.4
-- Designer:    SVB
-- Workgroup:   IRS16
--================================================================================
-- Keywords:    
-- Tools:       Altera Quartus 9.1 SP1
--    
-- Note:
-- 
-- 
-- 
-- Version History:
-- Ver 1.3.0 - Добавлены функции round и round2
--             Изменена реализация bus_key
--             Исключены bit_wider и shifter
-- Ver 1.3.1 - Добавлено описание функций замены
--             исключенным в версии 1.3.0
-- Ver 1.4.0 - Добавлена функция bit_reverse, реализующая зеркальное отражение
--             вектора.
-- Ver 1.4.1 - В функцию bit_reverse добавлен alias параметр
-- Ver 1.4.2 - В функции bit_num, bit_sum, or_bus добавлены alias параметры
-- Ver 1.4.3 - Замечена неверная метка версии 1.4.2(существует 2 варианта файлов
--             с такой меткой версии, один из них неверный)
-- Ver 1.4.4 - В функцию and_bus добавлены alias параметры
--
-- 
----------------------------------------------------------------------------------
    -- <метка>: entity work.rif_cmd_stm
----------------------------------------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package pkg_func is

	function log2_ceil(a: integer) return integer;
	function div_ceil(a: integer; b : integer) return integer;
    
	function or_bus(ARG : std_logic_vector ) return std_logic;
	function and_bus(ARG : std_logic_vector ) return std_logic;
    
	function bus_key(a : in std_logic_vector; b : in std_logic) return std_logic_vector;
    
	function bit_sum(ARG : std_logic_vector) return integer;
	function bit_num(ARG : std_logic_vector) return integer;
  
    function bit_reverse(v: std_logic_vector) return std_logic_vector;
    
    ------------------------------------------------------------------
    -- Исключена, пользоваться стандартной RESIZE для numeric_std.
    -- SXT и EXT для logic_arith
	-- function bit_wider(Arg : signed; Cnt : natural) return signed;
    
    ------------------------------------------------------------------
    -- Исключена, пользоваться стандартной SHIFT_RIGHT или 
    -- LEFT_RIGHT для numeric_std.
    -- SHL и SHR для logic_arith
	-- function shifter(Arg : signed; Sh : natural) return signed;
    
    ------------------------------------------------------------------
	function round(X : signed; trunc_bits : natural) return signed;
    -- Purpose:
        --      Функция возвращает число формата signed, разрядность которого 
        --      на trunc_bits двоичных знаков меньше разрядности XX.
        --      При этом число XX округляется к ближайшему целому.
        --
        -- Special values:
        --      Если отбрасываемая часть, являющаяся дробной, по
        --      модулю равна 0.5, число округляется к ближайшему
        --      большему целому.
        --
        -- Domain:
        --         
        -- Error conditions:
        --         None
        -- Range:
        --         
        -- Notes:
        --         
        
    ------------------------------------------------------------------
    function round2(X : signed; trunc_bits : natural) return signed;
    -- Purpose:
        --      Функция возвращает число формата signed, разрядность которого 
        --      на trunc_bits двоичных знаков меньше разрядности XX.
        --      При этом число XX округляется к ближайшему целому.
        --
        -- Special values:
        --      Если отбрасываемая часть, являющаяся дробной, по
        --      модулю равна 0.5, число округляется к ближайшему
        --      большему по модулю целому.
        --
        -- Domain:
        --         
        -- Error conditions:
        --         None
        -- Range:
        --         
        -- Notes:
        --         
        
    ------------------------------------------------------------------
    
	impure function random_value_gen(constant lower_value : in integer;
										constant upper_value : in integer) return integer;
	impure function random_value_gen(constant lower_value : in integer;
									 constant upper_value : in integer;
									 constant out_width   : in natural) return std_logic_vector;
                                     
end pkg_func;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package body pkg_func is
	
--=======================================================
--=======================================================   
-- function calculates ceil part of log2 of argument
	function log2_ceil(a : integer) return integer is
		variable temp : integer;
	begin
		temp := 0;
		for i in 0 to 30 loop
			if (a > (2**i)) then
				temp := i+1;
			end if;
		end loop;
		return(temp);
	end log2_ceil;
    
    
--=======================================================
--=======================================================
	function div_ceil(a: integer; b : integer) return integer is
		variable temp   : integer;
		variable result : integer;
	begin
		temp   := a;
		result := 0;
		while temp > 0 loop
			temp   := temp - b;
			result := result + 1;
		end loop;
		return(result);
	end div_ceil;
	
    
--=======================================================
--=======================================================    
--it makes the or operation betwen each of arg's bit
	function or_bus(ARG : std_logic_vector ) return std_logic is
		constant ARG_L  : INTEGER := ARG'LENGTH;
        alias    ARGX   : std_logic_vector(ARG_L-1 downto 0) is ARG;
        variable res    : std_logic := '0';
	begin
		res := ARGX(ARGX'low);
		for i in ARGX'low + 1 to ARGX'high loop
			res := res or ARGX(i);
		end loop;	
		return res;
	end function or_bus;
    
    
--=======================================================
--=======================================================
--it makes the and operation betwen each of arg's bit
	function and_bus( ARG : std_logic_vector ) return std_logic is
        constant ARG_L  : INTEGER := ARG'LENGTH;
        alias    ARGX   : std_logic_vector(ARG_L-1 downto 0) is ARG;
		variable res    : std_logic := '0';
	begin
		res := ARGX(ARGX'low);
		for i in ARGX'low + 1 to ARGX'high loop
			res := res and ARGX(i);
		end loop;	
		return res;
	end function and_bus;
    
    
--=======================================================
--=======================================================
--it makes the and operation with each of arg's bit and b
	function bus_key(a : in std_logic_vector; b : in std_logic) return std_logic_vector is
        constant WDT_A  : natural := a'length;
        alias    XA     : std_logic_vector(WDT_A-1 downto 0) is a;
        variable RES    : std_logic_vector(WDT_A-1 downto 0) := ( others => '0' );
    begin
        RES := XA and (XA'range => b);
        return RES;
    end bus_key;
    
    
--=======================================================
--=======================================================
-- function returns the sum of '1' bits in arg
	function bit_sum(ARG : std_logic_vector) return integer is
        constant ARG_L  : INTEGER := ARG'LENGTH;
        alias    ARGX   : std_logic_vector(ARG_L-1 downto 0) is ARG;
        variable res    : integer := 0;
	begin
		for n in ARGX'range loop
			if(ARGX(n) = '1')then
				res := res + 1;
			end if;
		end loop;
		
		return res;
	end function bit_sum;
    
    
--=======================================================
--=======================================================
-- function returns the number of last occurrence of '1' bits in arg
	function bit_num(ARG : std_logic_vector) return integer is
        constant ARG_L  : INTEGER := ARG'LENGTH;
        alias    ARGX   : std_logic_vector(ARG_L-1 downto 0) is ARG;
        variable res    : integer := -1;
	begin
		for n in ARGX'range loop
			if(ARGX(n) = '1')then
				res := n;
			end if;
		end loop;
		return res;
	end function bit_num;
    
    
--=======================================================
--=======================================================
-- function widen the capacity of signed Arg in Cnt bits
	function bit_wider(Arg : signed; Cnt : natural) return signed is
        variable tmp : signed(Arg'high + Cnt downto 0);
        constant lo  : integer := Arg'high + Cnt;
	begin
		for n in lo downto Arg'high+1 loop
			tmp(n) := Arg(Arg'high);
		end loop;
		for n in Arg'high downto 0 loop
			tmp(n) := Arg(n);
		end loop;

		return tmp;
	end function bit_wider;
    
    
--=======================================================
--=======================================================
--function make Sh-bits left shift operation 
	function shifter(Arg : signed; Sh : natural) return signed is
        variable tmp : signed(Arg'high downto 0);
	begin

		for n in Arg'high downto Sh loop
			tmp(n) := Arg(n-Sh);
		end loop;
		
		if(Sh>0) then
			for n in Sh-1 downto 0 loop
				tmp(n) := '0';
			end loop;
		end if;

		return tmp;
		
	end function shifter;
    
    
--=======================================================
--=======================================================
    function round(X : signed; trunc_bits : natural) return signed is
        constant ARG_L  : INTEGER := X'LENGTH;
        constant RES_L  : INTEGER := X'LENGTH - trunc_bits;
        alias XX        : signed(ARG_L-1 downto 0) is X;
        variable wval   : signed(ARG_L-1 downto 0) := (others => '0');
        variable res    : signed(RES_L-1 downto 0) := (others => '0');
    begin
        if(ARG_L <= trunc_bits) then
            ASSERT FALSE
            REPORT "wrong trunc_bits index"
            SEVERITY FAILURE;
        elsif(trunc_bits = 0)then
            return XX;
        else
            wval := SHIFT_RIGHT(XX, trunc_bits - 1) + 1;
            if( wval(RES_L+1) = wval(RES_L) )then
                res := wval(RES_L downto 1);
            else
                res := not wval(RES_L downto 1);
            end if;
        end if;
        return res;
    end round;
    
    
--=======================================================
--=======================================================
    function round2(X : signed; trunc_bits : natural) return signed is
        constant ARG_L  : INTEGER := X'LENGTH;
        alias XX        : signed(ARG_L-1 downto 0) is X;
        variable wval   : signed(ARG_L downto 0) := (others => '0');
        variable res    : signed(ARG_L-trunc_bits-1 downto 0) := (others => '0');
    begin
        if(ARG_L <= trunc_bits) then
            ASSERT FALSE
            REPORT "wrong trunc_bits index"
            SEVERITY FAILURE;
        elsif(trunc_bits = 0)then
            return XX;
        else
            if(XX > 0)then  wval := RESIZE(XX, ARG_L+1) + 2**(trunc_bits-1);
            else            wval := RESIZE(XX, ARG_L+1) + 2**(trunc_bits-1) - 1;
            end if;
            if( wval(ARG_L) = wval(ARG_L-1) )then
                res := wval(ARG_L-1 downto trunc_bits);
            else
                res := not wval(ARG_L-1 downto trunc_bits);
            end if;
        end if;
        return res;
    end round2;
    
    
--=======================================================    
-- bit_reverse(v) -------------------------------------
    function bit_reverse(v: std_logic_vector) return std_logic_vector is
    alias vx        : std_logic_vector(v'length-1 downto 0) is v;
    variable res    : std_logic_vector(vx'range);
    begin
        for i in vx'range loop
            res(vx'high - i) := vx(i);
        end loop;
        return(res);
    end bit_reverse;
    
    
--=======================================================
--=======================================================
--рандомное значение(равномерное распределение) в диапазоне [lower_value:upper_value]
	shared variable seed1:integer:=844396720;  -- uniform procedure seed1
	shared variable seed2:integer:=821616997;  -- uniform procedure seed2

	impure function random_value_gen(constant lower_value : in integer;
												  constant upper_value : in integer) return integer is
	variable result : integer;
	variable tmp_real : real;  -- return value from uniform procedure
	
	begin
		uniform(seed1,seed2,tmp_real);
		result:=integer(trunc((tmp_real * real(upper_value - lower_value)) + real(lower_value)));
		return result;
	end random_value_gen;

    
--=======================================================
--=======================================================
	impure function random_value_gen(constant lower_value : in integer;
									 constant upper_value : in integer;
									 constant out_width   : in natural) return std_logic_vector is
	variable result : integer;
	variable tmp_real : real;  -- return value from uniform procedure
	
	begin
		uniform(seed1,seed2,tmp_real);
		result:=integer(trunc((tmp_real * real(upper_value - lower_value)) + real(lower_value)));
		return std_logic_vector( to_signed(result, out_width) );
		
	end random_value_gen;

    
end pkg_func;
