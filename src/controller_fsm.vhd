----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv   : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type t_state is (S_CLEAR, S_LOAD_A, S_LOAD_B, S_RESULT);
    signal r_state : t_state := S_CLEAR;

begin

    -- State register
    process(i_adv)
    begin
        if rising_edge(i_adv) then
            if i_reset = '1' then
                r_state <= S_CLEAR;
            else
                case r_state is
                    when S_CLEAR =>
                        r_state <= S_LOAD_A;

                    when S_LOAD_A =>
                        r_state <= S_LOAD_B;

                    when S_LOAD_B =>
                        r_state <= S_RESULT;

                    when S_RESULT =>
                        r_state <= S_CLEAR;
                        
                        
                        
                        
                      
                        
                        
                        
                        
                end case;
            end if;
        end if;
    end process;

    -- One-hot output
    process(r_state)
    begin
    
    
        case r_state is
            when S_CLEAR =>
                o_cycle <= "0001";

            when S_LOAD_A =>
                o_cycle <= "0010";

            when S_LOAD_B =>
                o_cycle <= "0100";

            when S_RESULT =>
                o_cycle <= "1000";
                
                
                
                
                
                
                
                
        end case;
    end process;

end FSM;