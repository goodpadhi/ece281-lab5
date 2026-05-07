----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port (
        i_A      : in  STD_LOGIC_VECTOR (7 downto 0);
        i_B      : in  STD_LOGIC_VECTOR (7 downto 0);
        i_op     : in  STD_LOGIC_VECTOR (2 downto 0);
        o_result : out STD_LOGIC_VECTOR (7 downto 0);
        o_flags  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end ALU;

architecture Behavioral of ALU is

begin

    process(i_A, i_B, i_op)
        variable v_sum     : unsigned(8 downto 0);
        variable v_result   : STD_LOGIC_VECTOR(7 downto 0);
        variable v_negative : STD_LOGIC;
        variable v_zero     : STD_LOGIC;
        variable v_carry    : STD_LOGIC;
        variable v_overflow : STD_LOGIC;
    begin

        -- Default values
        v_sum     := (others => '0');
        v_result   := (others => '0');
        v_negative := '0';
        v_zero     := '0';
        v_carry    := '0';
        v_overflow := '0';

        case i_op is

            -- 000: ADD
            when "000" =>
                v_sum := unsigned('0' & i_A) + unsigned('0' & i_B);
                v_result := std_logic_vector(v_sum(7 downto 0));
                v_carry := v_sum(8);
                -- Overflow for addition:
                if (i_A(7) = i_B(7)) and (i_A(7) /= v_result(7)) then
                    v_overflow := '1';
                else
                    v_overflow := '0';
                end if;
            -- 001: SUBTRACT
            -- A - B = A + not(B) + 1
            
            
            
            
            
            
            when "001" =>
                v_sum := unsigned('0' & i_A) + unsigned('0' & (not i_B)) + to_unsigned(1, 9);
                v_result := std_logic_vector(v_sum(7 downto 0));
                v_carry := v_sum(8);
                -- Overflow for subtraction:
                if (i_A(7) /= i_B(7)) and (i_A(7) /= v_result(7)) then
                    v_overflow := '1';
                else
                    v_overflow := '0';
                end if;

            -- 010: AND
            when "010" =>
                v_result := i_A and i_B;

            -- 011: OR
            when "011" =>
                v_result := i_A or i_B;

            -- unused operations
            when others =>
                v_result := (others => '0');

        end case;

        -- Negative flag: MSB of result
        v_negative := v_result(7);




        -- Zero flag: result is all zeros
        if v_result = x"00" then
            v_zero := '1';
        else
            v_zero := '0';
        end if;

        -- Output result
        o_result <= v_result;






        -- Flags
        o_flags <= v_negative & v_zero & v_carry & v_overflow;

    end process;

end Behavioral;
