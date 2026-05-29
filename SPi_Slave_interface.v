module SPI_Slave(
    input MOSI, SS_n, clk, rst_n, tx_valid,
    input [7:0] tx_data,
    output reg MISO, rx_valid,
    output reg [9:0] rx_data
);
    parameter ST_IDLE = 3'b000;
    parameter ST_CHECK_CMD = 3'b001;
    parameter ST_WRITE = 3'b010;
    parameter ST_READ_ADDR = 3'b011;
    parameter ST_READ_DATA = 3'b100;
    
    reg address_read_flag;
    reg [3:0] bit_counter;
    reg [2:0] current_state, next_state;
    
    always @(posedge clk) begin 
        if (~rst_n)
            current_state <= ST_IDLE;
        else 
            current_state <= next_state;
    end
    
    always @(*) begin 
        case(current_state)
            ST_IDLE: begin
                if (SS_n)
                    next_state = ST_IDLE;
                else 
                    next_state = ST_CHECK_CMD;
            end
            ST_CHECK_CMD: begin
                if (SS_n)
                    next_state = ST_IDLE;
                else begin
                    if (~MOSI) begin 
                        next_state = ST_WRITE;
                    end 
                    else begin
                        casex(address_read_flag)
                            1'b0: next_state = ST_READ_ADDR;
                            1'b1: next_state = ST_READ_DATA;
                            1'bx: next_state = ST_READ_ADDR;
                        endcase
                    end
                end
            end
            ST_WRITE: begin
                if (SS_n == 0)
                    next_state = ST_WRITE;
                else begin
                    next_state = ST_IDLE;
                end
            end
            ST_READ_ADDR: begin
                if (SS_n == 0) begin
                    next_state = ST_READ_ADDR;
                end
                else begin
                    next_state = ST_IDLE;
                end
            end
            ST_READ_DATA: begin
                if (SS_n == 0)
                    next_state = ST_READ_DATA;
                else begin
                    next_state = ST_IDLE;
                end
            end
        endcase
    end
    
    always @(posedge clk) begin
        if (~rst_n) begin 
            rx_data <= 0;
            rx_valid <= 0;
            address_read_flag <= 0;
            MISO <= 0;
        end
        else begin
            case(current_state)
                ST_IDLE: rx_valid <= 0;
                ST_CHECK_CMD: begin
                    bit_counter <= 10;
                end
                ST_WRITE: begin
                    if (bit_counter > 0) begin
                        rx_data[bit_counter-1] <= MOSI;
                        bit_counter <= bit_counter - 1;
                    end
                    else begin
                        rx_valid <= 1;
                    end
                end
                ST_READ_ADDR: begin
                    if (bit_counter > 0) begin
                        rx_data[bit_counter-1] <= MOSI;
                        bit_counter <= bit_counter - 1;
                    end
                    else begin
                        rx_valid <= 1;
                        address_read_flag <= 1;
                    end
                end
                ST_READ_DATA: begin
                    if (tx_valid) begin
                        if (bit_counter > 0) begin
                            MISO <= tx_data[bit_counter-1];
                            bit_counter <= bit_counter - 1;
                        end
                        else begin
                            address_read_flag <= 0;
                            rx_valid <= 0;
                        end
                    end
                    else begin 
                        if (bit_counter > 0) begin
                            rx_data[bit_counter-1] <= MOSI;
                            bit_counter <= bit_counter - 1;
                        end
                        else begin
                            rx_valid <= 1;
                            bit_counter <= 9;
                        end
                    end
                end
            endcase
        end
    end
endmodule