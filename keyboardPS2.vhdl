library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboardPS2 is
    port(
        keyboard_clk, keyboard_data, clk_25Mhz, reset, enable : in  std_logic;
        parity_error, scan_ready                              : out std_logic;
        scan_code                         : out std_logic_vector(7 downto 0));
end entity;

architecture behavioral of keyboardPS2 is
    Type State is(IDLE,start);
    signal read_char  : std_logic := '0';
    signal ready_set  : std_logic := '0';
    signal ver_parity : std_logic := '0';

    signal keyboard_clk_filtered : std_logic;

    signal filter   : std_logic_vector(7 downto 0);
    signal incount  : unsigned        (3 downto 0) := "0000";
    signal shift_in : std_logic_vector(8 downto 0) :="000000000";

    signal present:state := IDLE;

begin

    clock_filter : process
    begin
        wait until clk_25Mhz'event and clk_25Mhz = '1';
        filter(6 downto 0) <= filter(7 downto 1);
        filter(7) <= keyboard_clk;
        if filter = x"FF" then
            keyboard_clk_filtered <= '1';
        elsif filter = x"00" then 
            keyboard_clk_filtered <= '0';
        end if;
    end process;

    process (keyboard_clk_filtered)
    begin
    if reset = '1' then
        incount <= x"0";
        read_char <= '0';
     else
    if (keyboard_clk_filtered'event and keyboard_clk_filtered = '0') then
    case present is

       when IDLE =>
       if keyboard_data = '0' and read_char = '0' then
                shift_in <= "000000000";
                ver_parity <= '0';
                read_char <= '1';
                ready_set <= '0';
                present <= start;
        end if;

       when start =>
       if incount < x"9" then
              shift_in(7 downto 0) <= shift_in(8 downto 1);
              shift_in(8) <= keyboard_data;
              ready_set <= '0';
              ver_parity <= ver_parity xor keyboard_data;
              incount <= incount + 1;
        else
            parity_error <= ver_parity xor keyboard_data;
            scan_code <= shift_in(7 downto 0);
            read_char <= '0';
            ready_set <= '1';
            incount <= x"0";
            present <= IDLE;
        end if;
       when others => null;
       end case;
       end if;
        end if;
       end process;

    process (enable, ready_set)
    begin
        if enable = '1' then
            scan_ready <= '0';
        elsif ready_set'event and ready_set = '1' then
            scan_ready <= '1';
            else
             scan_ready <= '0';
        end if;
    end process;

end behavioral ;
