import RAM_test_pkg::*;
import RAM_env_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

module RAM_top();
    bit clk;

    initial begin
        forever #10 clk = ~clk;
    end

    RAM_if ramif (clk);
    RAM    DUT (ramif);

    bind RAM RAM_SVA RAM_assertions (ramif);   
    initial begin
        uvm_config_db #(virtual RAM_if)::set(null, "uvm_test_top", "RAM_V", ramif);
        run_test("RAM_test");
    end
endmodule