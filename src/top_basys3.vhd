--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 

    -- COMPONENTS ---------------------------------------

    component ALU is
        Port (
            i_A      : in  std_logic_vector(7 downto 0);
            i_B      : in  std_logic_vector(7 downto 0);
            i_op     : in  std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags  : out std_logic_vector(3 downto 0)
        );
    end component;

    component controller_fsm is
        Port (
            i_reset : in  std_logic;
            i_adv   : in  std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
        );
    end component;

    -- IMPORTANT:
    -- If your sevenseg_decoder has different port names,
    -- change these names to match your file.
    component sevenseg_decoder is
        Port (
            i_digit : in  std_logic_vector(3 downto 0);
            o_seg   : out std_logic_vector(6 downto 0)
        );
    end component;

    -- SIGNALS ------------------------------------------

    signal w_cycle      : std_logic_vector(3 downto 0);
    signal w_alu_result : std_logic_vector(7 downto 0);
    signal w_flags      : std_logic_vector(3 downto 0);

    signal r_A : std_logic_vector(7 downto 0) := (others => '0');
    signal r_B : std_logic_vector(7 downto 0) := (others => '0');

    signal w_display_value : std_logic_vector(7 downto 0);

    signal w_negative  : std_logic;
    signal w_abs_value : integer range 0 to 128;

    signal w_hundreds : std_logic_vector(3 downto 0);
    signal w_tens     : std_logic_vector(3 downto 0);
    signal w_ones     : std_logic_vector(3 downto 0);

    signal r_refresh_count : unsigned(15 downto 0) := (others => '0');
    signal w_digit_select  : std_logic_vector(1 downto 0);

    signal w_current_digit : std_logic_vector(3 downto 0);
    signal w_digit_seg     : std_logic_vector(6 downto 0);

    signal w_blank_digit : std_logic;
    signal w_minus_digit : std_logic;

    constant c_blank_seg : std_logic_vector(6 downto 0) := "1111111";
    constant c_minus_seg : std_logic_vector(6 downto 0) := "0111111";

begin

    -- PORT MAPS ----------------------------------------

    u_controller : controller_fsm
        port map (
            i_reset => btnU,
            i_adv   => btnC,
            o_cycle => w_cycle
        );

    u_ALU : ALU
        port map (
            i_A      => r_A,
            i_B      => r_B,
            i_op     => sw(2 downto 0),
            o_result => w_alu_result,
            o_flags  => w_flags
        );

    u_sevenseg_decoder : sevenseg_decoder
        port map (
            i_digit => w_current_digit,
            o_seg   => w_digit_seg
        );

    -- REGISTER LOGIC -----------------------------------
    -- Because the FSM changes state on btnC, we load based on
    -- the state we are leaving.

    process(btnC)
    begin
        if rising_edge(btnC) then
            if btnU = '1' then
                r_A <= (others => '0');
                r_B <= (others => '0');
            else
                case w_cycle is

                    -- leaving CLEAR, going to LOAD_A
                    when "0001" =>
                        r_A <= sw;

                    -- leaving LOAD_A, going to LOAD_B
                    when "0010" =>
                        r_B <= sw;

                    when others =>
                        null;

                end case;
            end if;
        end if;
    end process;

    -- DISPLAY VALUE MUX --------------------------------
    -- Choose what number should appear on the display.

    with w_cycle select
        w_display_value <= r_A           when "0010",
                           r_B           when "0100",
                           w_alu_result  when "1000",
                           (others => '0') when others;

    -- CONVERT TWO'S COMPLEMENT VALUE TO DECIMAL DIGITS --

    process(w_display_value)
        variable v_int : integer;
        variable v_abs : integer;
    begin
        v_int := to_integer(signed(w_display_value));

        if v_int < 0 then
            w_negative <= '1';
            v_abs := -v_int;
        else
            w_negative <= '0';
            v_abs := v_int;
        end if;

        w_abs_value <= v_abs;

        w_hundreds <= std_logic_vector(to_unsigned(v_abs / 100, 4));
        w_tens     <= std_logic_vector(to_unsigned((v_abs / 10) mod 10, 4));
        w_ones     <= std_logic_vector(to_unsigned(v_abs mod 10, 4));
    end process;

    -- REFRESH COUNTER FOR MULTIPLEXING -----------------

    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                r_refresh_count <= (others => '0');
            else
                r_refresh_count <= r_refresh_count + 1;
            end if;
        end if;
    end process;

    w_digit_select <= std_logic_vector(r_refresh_count(15 downto 14));

    -- SEVEN-SEGMENT MULTIPLEXING -----------------------

    process(w_digit_select, w_cycle, w_hundreds, w_tens, w_ones, w_negative, w_abs_value)
    begin
        an <= "1111";
        w_current_digit <= "0000";
        w_blank_digit <= '1';
        w_minus_digit <= '0';

        -- CLEAR state: blank display
        if w_cycle = "0001" then
            an <= "1111";
            w_blank_digit <= '1';

        else
            case w_digit_select is

                -- rightmost digit: ones
                when "00" =>
                    an <= "1110";
                    w_current_digit <= w_ones;
                    w_blank_digit <= '0';

                -- tens digit
                when "01" =>
                    an <= "1101";
                    w_current_digit <= w_tens;

                    if w_abs_value < 10 then
                        w_blank_digit <= '1';
                    else
                        w_blank_digit <= '0';
                    end if;

                -- hundreds digit
                when "10" =>
                    an <= "1011";
                    w_current_digit <= w_hundreds;

                    if w_abs_value < 100 then
                        w_blank_digit <= '1';
                    else
                        w_blank_digit <= '0';
                    end if;

                -- leftmost digit: minus sign if negative
                when others =>
                    an <= "0111";

                    if w_negative = '1' then
                        w_minus_digit <= '1';
                        w_blank_digit <= '0';
                    else
                        w_blank_digit <= '1';
                    end if;

            end case;
        end if;
    end process;

    -- FINAL SEGMENT OUTPUT -----------------------------

    seg <= c_blank_seg when w_blank_digit = '1' else
           c_minus_seg when w_minus_digit = '1' else
           w_digit_seg;

    -- LED OUTPUTS --------------------------------------

    led(3 downto 0)   <= w_cycle;
    led(11 downto 4)  <= (others => '0');
    led(15 downto 12) <= w_flags;

end top_basys3_arch;
