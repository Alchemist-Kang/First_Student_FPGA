module tenthirty(
    input clk,
    input rst_n, //negedge reset
    input btn_m, //bottom middle
    input btn_r, //bottom right
    output reg [7:0] seg7_sel,
    output reg [7:0] seg7,   //segment right
    output reg [7:0] seg7_l, //segment left
    output reg [2:0] led // led[0] : player win, led[1] : dealer win, led[2] : done
);

//================================================================
//   PARAMETER
//================================================================
parameter IDLE = 3'b000;
parameter DORO = 3'b001;
parameter PMANY_DORO = 3'b010;
parameter PCOMPARE = 3'b011;
parameter DMANY_DORO = 3'b100;
parameter DCOMPARE = 3'b101;
parameter FINAL = 3'b110;
parameter DONE = 3'b111;
integer i;

//================================================================
//   d_clk
//================================================================
//frequency division
reg [24:0] counter; 
wire dis_clk; //seg display clk
wire d_clk  ; //division clk

//====== frequency division ======
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
    end
end
assign d_clk = counter[24];
assign dis_clk = counter[12];

//================================================================
//   REG/WIRE
//================================================================
//seg7_temp
reg [7:0] seg7_temp[0:7];           //displayomg value???

reg [2:0] dis_cnt;
reg [4:0] card_dealer[0:4];
reg [4:0] card_player[0:4];
reg [1:0] doro_count;
reg [2:0] p_cards;
reg [2:0] d_cards;
reg [2:0] round;
wire[5:0] P_total;
wire[5:0] D_total;
//================================================================
//   FSM
//================================================================
reg [2:0]current_state;
reg [2:0]next_state;

always@(posedge d_clk, negedge rst_n)begin            // work at dclk
    if(!rst_n)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

always@(*)begin    
    if(!rst_n)begin
        next_state = IDLE;
    end

    else begin
        case(current_state)
            IDLE: begin
                if(btn_m)begin
                    next_state = DORO;
                end

                else begin
                    next_state = IDLE;
                end
            end

            DORO: begin
                if(doro_count == 2'b10)begin                           /// 
                    next_state = PMANY_DORO;
                end

                else begin
                    next_state = DORO;
                end
            end

            PMANY_DORO: begin
                if(P_total > 6'd21)begin
                    next_state = DMANY_DORO;
                end

                else if(btn_r)begin
                    next_state = DMANY_DORO;
                end

                else if(p_cards == 3'd5)begin
                    if(btn_m)begin
                        next_state = DMANY_DORO;
                    end
                    else if(btn_r)begin
                        next_state = DMANY_DORO;
                    end
                    else begin
                        next_state = PMANY_DORO;
                    end
                end
                else begin
                    if(btn_m)begin                       ///need revise
                        next_state = PCOMPARE;
                    end
                    else begin
                        next_state = PMANY_DORO;
                    end
                end
            end

            PCOMPARE: begin
                next_state = PMANY_DORO;
            end

            DMANY_DORO: begin
                if(D_total > 6'd21)begin
                    next_state = FINAL;
                end

                else if(btn_r)begin
                    next_state = FINAL;
                end

                else if(d_cards == 3'd5)begin
                    if(btn_m)begin
                        next_state = FINAL;
                    end

                    else if(btn_r)begin
                        next_state = FINAL;
                    end

                    else begin
                        next_state = DMANY_DORO;
                    end
                end

                else begin
                    if(btn_m)begin
                        next_state = DCOMPARE;
                    end

                    else begin
                        next_state = DMANY_DORO;
                    end
                end
            end

            DCOMPARE: begin
                next_state = DMANY_DORO;
            end

            FINAL: begin
                if(btn_r)begin
                    if(round == 3'd3)begin
                        next_state = DONE;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
                else begin
                    next_state = FINAL;
                end
            end

            DONE: begin
                next_state = DONE;
            end
            default: next_state = IDLE;
        endcase
    end
end


//================================================================
//   I/O
//================================================================
reg  pip;
wire [3:0] number;

always@(*)begin                                     // pip work at dclk
    if((current_state == DORO) && (!doro_count[1]))begin
        pip = 1'b1;
    end
    else if((current_state == PMANY_DORO) || (current_state == DMANY_DORO))begin
        if(btn_m)begin
            pip = 1'b1;
        end
        else begin
            pip = 1'b0;
        end
    end
    else begin
        pip = 1'b0;
    end

end


//================================================================
//   DESIGN
//================================================================


always@(posedge d_clk , negedge rst_n)begin     //DORO stage player 1 Dealer 1
    if(!rst_n)begin
        doro_count <= 2'b00;
    end
    else begin
        if(current_state == DORO)begin
            doro_count <= doro_count + 1'b1;
        end
        else begin
            doro_count <= 2'b00;
        end
    end
end

always@(posedge d_clk , negedge rst_n)begin     // 可以補最多四張
    if(!rst_n)begin
        p_cards <= 3'd1;
    end
    else begin
        if(current_state == IDLE)begin
            p_cards <= 3'd1;
        end
        else if((current_state == PCOMPARE))begin
            p_cards <= p_cards +1;
        end
        else begin
            p_cards <= p_cards ;
        end
    end
end

always@(posedge d_clk , negedge rst_n)begin     // 可以補最多四張
    if(!rst_n)begin
        d_cards <= 3'd1;
    end
    else begin
        if(current_state == IDLE)begin
            d_cards <= 3'd1;
        end
        else if((current_state == DCOMPARE))begin
            d_cards <= d_cards +1;
        end
        else begin
            d_cards <= d_cards ;
        end
    end
end


always@(posedge d_clk , negedge rst_n)begin         // dealer temp
    if(!rst_n)begin
        for(i=0;i<=4;i=i+1)begin
            card_dealer[i] <= 5'd0;
        end
    end

    else if(current_state == IDLE)begin
        for(i=0;i<=4;i=i+1)begin
            card_dealer[i] <= 5'd0;
        end
    end

    else begin
        if(current_state == DORO)begin
            if(doro_count == 2'b10)begin
                if(number > 10)begin
                    card_dealer[0] <= 5'b0_0001;
                end
                else begin
                    card_dealer[0] <= {number, 1'b0};
                end
            end
            else begin          //Keep
                card_dealer[0] <= card_dealer[0];
            end
        end

        else if(current_state == DCOMPARE)begin
            if((number > 10))begin
                card_dealer[d_cards] <= 5'b0_0001;
            end
            else if((number <=10)) begin
                card_dealer[d_cards] <= {number, 1'b0};
            end
            else begin          //Keep
                card_dealer[d_cards] <= card_dealer[d_cards];
            end
        end

        else begin                                  //Keep
            for(i=0;i<5;i=i+1)begin
                card_dealer[i] <= card_dealer[i];
            end
        end
    end
end

always@(posedge d_clk, negedge rst_n)begin         //player temp
    if(!rst_n)begin
        for(i=0; i<=4; i=i+1)begin
            card_player[i] <= 5'd0;
        end
    end
    else if(current_state == IDLE)begin
        for(i=0;i<=4;i=i+1)begin
            card_player[i] <= 5'd0;
        end
    end

    else begin
        if(current_state == DORO)begin
            if(doro_count == 2'b01)begin
                if(number >10)begin
                    card_player[0] <= 5'b0_0001;
                end
                else begin
                    card_player[0] <= {number, 1'b0};
                end
            end
            else begin      //Keep
                card_player[0] <= card_player[0];
            end
        end

        else if((current_state == PCOMPARE))begin
            if(number != 'd0)begin
                if((number>10))begin
                    card_player[p_cards] <= 5'b0_0001;
                end
                else if((number <= 10))begin
                    card_player[p_cards] <= {number, 1'b0};
                end
            end
            else begin
                card_player[p_cards] <= card_player[p_cards];
            end
        end

        else begin          //Keep
            for(i=0;i<5;i=i+1)begin
                card_player[i] <= card_player[i];
            end
        end 

    end
end

always@(posedge d_clk, negedge rst_n)begin      //round 回合
    if(!rst_n)begin
        round <= 3'd0;
    end
    else begin
        if((current_state == FINAL) && (btn_r))begin
            round <= round + 1'b1;
        end
        else begin          //Keep
            round <= round;
        end
    end
end

/// P_total & D_total
assign P_total = card_player[0] + card_player[1] + card_player[2] + card_player[3] + card_player[4];
assign D_total = card_dealer[0] + card_dealer[1] + card_dealer[2] + card_dealer[3] + card_dealer[4]; 


always@(posedge d_clk, negedge rst_n)begin             // number into 7-seg display format      [7:0]seg7_temp[0:7]
    if(!rst_n)begin
        for(i=0;i<8;i=i+1)begin
            seg7_temp[i] <= 8'b0000_0001;
        end
    end

    else begin
        if(current_state == IDLE)begin
            for(i=0;i<8;i=i+1)begin
                seg7_temp[i] <= 8'b0000_0001;
            end
        end

        else if((current_state == PMANY_DORO) || (current_state == PCOMPARE))begin
                seg7_temp[5] <= (P_total[0])? 8'b1000_0000: 8'b0000_0001;
                seg7_temp[7] <= (P_total[5:1]>= 'd20)? 8'b0101_1011: ((P_total[5:1]>= 'd10)? 8'b0000_0110:8'b0011_1111);
                case(P_total[5:1]%10)
                    0: seg7_temp[6] <= 8'b0011_1111;
                    1: seg7_temp[6] <= 8'b0000_0110;
                    2: seg7_temp[6] <= 8'b0101_1011;
                    3: seg7_temp[6] <= 8'b0100_1111;
                    4: seg7_temp[6] <= 8'b0110_0110;
                    5: seg7_temp[6] <= 8'b0110_1101;
                    6: seg7_temp[6] <= 8'b0111_1101;
                    7: seg7_temp[6] <= 8'b0000_0111;
                    8: seg7_temp[6] <= 8'b0111_1111;
                    9: seg7_temp[6] <= 8'b0110_1111;
                    default: seg7_temp[6] <= 8'b0000_0001;
                endcase
                for(i=0;i<5;i=i+1)begin
                    case((card_player[i]))
                         0: seg7_temp[i] <= 8'b0000_0001;
                         1: seg7_temp[i] <= 8'b1000_0000;
                         2: seg7_temp[i] <= 8'b0000_0110;
                         4: seg7_temp[i] <= 8'b0101_1011;
                         6: seg7_temp[i] <= 8'b0100_1111;
                         8: seg7_temp[i] <= 8'b0110_0110;
                        10: seg7_temp[i] <= 8'b0110_1101;
                        12: seg7_temp[i] <= 8'b0111_1101;
                        14: seg7_temp[i] <= 8'b0000_0111;
                        16: seg7_temp[i] <= 8'b0111_1111;
                        18: seg7_temp[i] <= 8'b0110_1111;
                        20: seg7_temp[i] <= 8'b0011_1111;
                        default: seg7_temp[i] <= 8'b0000_0001;
                    endcase
                end
        end
        else if((current_state == DMANY_DORO) || (current_state == DCOMPARE))begin
                seg7_temp[5] <= (D_total[0])? 8'b1000_0000: 8'b0000_0001;
                seg7_temp[7] <= (D_total[5:1]>= 'd20)? 8'b0101_1011: ((D_total[5:1] >= 'd10)? 8'b0000_0110:8'b0011_1111);
                case(D_total[5:1]%10)
                    0: seg7_temp[6] <= 8'b0011_1111;
                    1: seg7_temp[6] <= 8'b0000_0110;
                    2: seg7_temp[6] <= 8'b0101_1011;
                    3: seg7_temp[6] <= 8'b0100_1111;
                    4: seg7_temp[6] <= 8'b0110_0110;
                    5: seg7_temp[6] <= 8'b0110_1101;
                    6: seg7_temp[6] <= 8'b0111_1101;
                    7: seg7_temp[6] <= 8'b0000_0111;
                    8: seg7_temp[6] <= 8'b0111_1111;
                    9: seg7_temp[6] <= 8'b0110_1111;
                    default: seg7_temp[6] <= 8'b0000_0001;
                endcase
                for(i=0;i<5;i=i+1)begin
                    case((card_dealer[i]))
                         0: seg7_temp[i] <= 8'b0000_0001;
                         1: seg7_temp[i] <= 8'b1000_0000;
                         2: seg7_temp[i] <= 8'b0000_0110;
                         4: seg7_temp[i] <= 8'b0101_1011;
                         6: seg7_temp[i] <= 8'b0100_1111;
                         8: seg7_temp[i] <= 8'b0110_0110;
                        10: seg7_temp[i] <= 8'b0110_1101;
                        12: seg7_temp[i] <= 8'b0111_1101;
                        14: seg7_temp[i] <= 8'b0000_0111;
                        16: seg7_temp[i] <= 8'b0111_1111;
                        18: seg7_temp[i] <= 8'b0110_1111;
                        20: seg7_temp[i] <= 8'b0011_1111;
                        default: seg7_temp[i] <= 8'b0000_0001;
                    endcase
                end 
        end

        else if(current_state == FINAL) begin
            seg7_temp[3] <= 8'b0000_0001;
            seg7_temp[4] <= 8'b0000_0001;
            // dealer
            seg7_temp[5] <= (D_total[0])? 8'b1000_0000: 8'b0000_0001;
            seg7_temp[7] <= (D_total[5:1]>= 'd20)? 8'b0101_1011: ((D_total[5:1] >= 'd10)? 8'b0000_0110:8'b0011_1111);
            case(D_total[5:1]%10)
                0: seg7_temp[6] <= 8'b0011_1111;
                1: seg7_temp[6] <= 8'b0000_0110;
                2: seg7_temp[6] <= 8'b0101_1011;
                3: seg7_temp[6] <= 8'b0100_1111;
                4: seg7_temp[6] <= 8'b0110_0110;
                5: seg7_temp[6] <= 8'b0110_1101;
                6: seg7_temp[6] <= 8'b0111_1101;
                7: seg7_temp[6] <= 8'b0000_0111;
                8: seg7_temp[6] <= 8'b0111_1111;
                9: seg7_temp[6] <= 8'b0110_1111;
                default: seg7_temp[6] <= 8'b0000_0001;
            endcase

            // player
            seg7_temp[0] <= (P_total[0])? 8'b1000_0000: 8'b0000_0001;
            seg7_temp[2] <= (P_total[5:1]>= 'd20)? 8'b0101_1011: ((P_total[5:1] >= 'd10)? 8'b0000_0110:8'b0000_0000);
            case(P_total[5:1]%10)
                0: seg7_temp[1] <= 8'b0011_1111;
                1: seg7_temp[1] <= 8'b0000_0110;
                2: seg7_temp[1] <= 8'b0101_1011;
                3: seg7_temp[1] <= 8'b0100_1111;
                4: seg7_temp[1] <= 8'b0110_0110;
                5: seg7_temp[1] <= 8'b0110_1101;
                6: seg7_temp[1] <= 8'b0111_1101;
                7: seg7_temp[1] <= 8'b0000_0111;
                8: seg7_temp[1] <= 8'b0111_1111;
                9: seg7_temp[1] <= 8'b0110_1111;
                default: seg7_temp[1] <= 8'b0000_0001;
            endcase
        end

        else begin      //Keep
            for(i=0;i<8;i=i+1)begin
                seg7_temp[i] <= seg7_temp[i];
            end
        end
        
    end

end



//================================================================
//   SEGMENT
//================================================================
//display counter 
always@(posedge dis_clk or negedge rst_n) begin
    if(!rst_n) begin
        dis_cnt <= 0;
    end
    else begin
        dis_cnt <= (dis_cnt >= 7) ? 0 : (dis_cnt + 1);
    end
end

always @(posedge dis_clk or negedge rst_n) begin 
    if(!rst_n) begin
        seg7 <= 8'b0000_0001;
    end 
    else begin
        if(!dis_cnt[2]) begin
            seg7 <= seg7_temp[dis_cnt];
        end
    end
end

always @(posedge dis_clk or negedge rst_n) begin 
    if(!rst_n) begin
        seg7_l <= 8'b0000_0001;
    end 
    else begin
        if(dis_cnt[2]) begin
            seg7_l <= seg7_temp[dis_cnt];
        end
    end
end

always@(posedge dis_clk or negedge rst_n) begin
    if(!rst_n) begin
        seg7_sel <= 8'b11111111;
    end
    else begin
        case(dis_cnt)
            0 : seg7_sel <= 8'b00000001;
            1 : seg7_sel <= 8'b00000010;
            2 : seg7_sel <= 8'b00000100;
            3 : seg7_sel <= 8'b00001000;
            4 : seg7_sel <= 8'b00010000;
            5 : seg7_sel <= 8'b00100000;
            6 : seg7_sel <= 8'b01000000;
            7 : seg7_sel <= 8'b10000000;
            default : seg7_sel <= 8'b11111111;
        endcase
    end
end

//================================================================
//   LED
//================================================================
always@(posedge dis_clk , negedge rst_n)begin     //
    if(!rst_n)begin
        led <= 3'b000;
    end

    else if(current_state == DONE)begin
        led <= 3'b100;
    end

    else if(current_state == FINAL)begin
        if(P_total > 6'd21)begin
            led <= 3'b010;
        end
        else if(D_total > 6'd21)begin
            led <= 3'b001;
        end
        else begin
            if(D_total >= P_total)begin
                led <= 3'b010;
            end
            else begin
                led <= 3'b001;
            end
        end
    end

    else begin              // compare the two players and who win :   led[0] : dealer win, led[1] : player win, led[2] : done
        led <= 3'b000;
    end
end

//================================================================
//   LUT Instantiation
//================================================================
LUT L1(.clk(d_clk) ,.rst_n(rst_n) ,.pip(pip) ,.number(number));
endmodule 