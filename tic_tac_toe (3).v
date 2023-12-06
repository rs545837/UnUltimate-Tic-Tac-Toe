`timescale 1ns / 1ps

module tic_tac_toe(
    input  wire CLK,                 // 100 MHz Clock
    input  wire RST_BTN,             // reset button

    input  wire [3:0] ROW,            // 1-bit PS2_DATA pin
    output wire [3:0] COL,

    output wire VGA_HS_O,            // horizontal sync output
    output wire VGA_VS_O,            // vertical sync output
    output wire [3:0] VGA_R,         // 4-bit VGA red output
    output wire [3:0] VGA_G,         // 4-bit VGA green output
    output wire [3:0] VGA_B,        // 4-bit VGA blue output

    output wire [3:0] led_score_p1,  // 4-bit LED output (Player 1)
    output reg  [3:0] led_score_p2   // 4-bit LED output (Player 2)
    );
     
    wire reset = RST_BTN;
    wire [3:0] key_code;

    // Key parameters
    parameter [3:0] ARROW_UP = 4'b0010;    // 2
    parameter [3:0] ARROW_DOWN = 4'b1000;   // 8
    parameter [3:0] ARROW_LEFT = 4'b0100;   // 4
    parameter [3:0] ARROW_RIGHT = 4'b0110;  // 6
    parameter [3:0] ENTER = 4'b0101;        // 5
    parameter [3:0] ESCAPE = 4'b1101;       // D
    parameter [3:0] NEXT = 4'b1100;
    
    // Values for game logic
    reg [2:0] curr_row    = 3'b010;     // Current row
    reg [2:0] curr_col = 3'b010;        // Current column
    reg curr_player = 0;                // Current player (0: Player1, 1: Player2)
    wire player_1_win, player_2_win;     // Player win conditions
    reg [3:0] player_1_score = 0;        // Player 1 score (0-15)
    reg [3:0] player_2_score = 0;        // Player 2 score (0-15)
    reg game_over = 0;                   // Game end

    
    // Values for game display
    reg  [9:1] player1_squares = 9'b000000000;             // Position of player 1's squares
    reg  [9:1] player2_squares = 9'b000000000;             // Position of player 2's squares
    reg  [9:1] curr_square = 9'b000010000;          // Position of selector
    wire [9:0] x;                                   // 10-bit x pixel: 0-1023 for xmax=640
    wire [8:0] y;                                   //  9-bit y pixel: 0-511  for ymax=480

    // module that implements the VGA Controller for 640x480 resolution
    vga640x480 display (
        .i_clk(CLK),
        .i_rst(reset),
        .o_hs(VGA_HS_O),
        .o_vs(VGA_VS_O),
        .o_x(x),
        .o_y(y)
    );
   
    // module that implements the Keyboard Controller
    keyboard_controller keyboard_input(
        .clk(CLK),        //board clock
        .row(ROW),    //keyboard clock and data signals
        .col(COL),    
        .key(key_code)
   );
   
   // displays game board
   generate_graphics graphics_display(
        .i_selected_square_pos(curr_square),  
        .i_player_1_square_pos(player1_squares),
        .i_player_2_square_pos(player2_squares),
        .i_x(x),                            // current pixel x position: 10-bit value: 0-1023 for xmax=640
        .i_y(y),                             // current pixel y position:  9-bit value: 0-511  for ymax=480
        .o_VGA_R(VGA_R),
        .o_VGA_B(VGA_B),
        .o_VGA_G(VGA_G)
    );
   
    // module that checks whether either player has won the game
    verify_positions check_winner(
        .i_player_1_square_pos(player1_squares),
        .i_player_2_square_pos(player2_squares),
        .i_player_1_win(player_1_win),
        .i_player_2_win(player_2_win)
    );
    
    //reg flag = 0;
    always @ (posedge CLK)
    begin
//        if(key_code == NEXT)begin
          //flag = 1;
//        end
        // resets the starting position of the selected square if ESC or the restart button is pressed
        if(reset | key_code == ESCAPE)
        begin
            curr_row <= 3'b010;
            curr_col <= 3'b010;
        end
            // checks if any arrow key was pressed on the keyboard, if so it changes the position
            // of the currently selected square on the board
            if (!game_over)
            begin    
                //if (key_code == ARROW_UP & flag == 1)
                if (key_code == ARROW_UP)
                    if (curr_row > 1)
                        curr_row = curr_row - 1;
//                        flag=0;
                         
                if (key_code == ARROW_DOWN)
                    if (curr_row < 3)
                        curr_row = curr_row + 1;  
                        //flag=0;
                        
                if (key_code == ARROW_LEFT)
                    if (curr_col > 1)
                        curr_col = curr_col - 1;
                        //flag=0;
                        
                if (key_code == ARROW_RIGHT)
                    if (curr_col < 3)
                        curr_col = curr_col + 1;        
                       // flag=0;
                             
                if(curr_col == 1 & curr_row == 1)
                    curr_square <= 9'b000000001;
                if(curr_col == 2 & curr_row == 1)
                    curr_square <= 9'b000000010;
                if(curr_col == 3 & curr_row == 1)
                    curr_square <= 9'b000000100;
                if(curr_col == 1 & curr_row == 2)
                    curr_square <= 9'b000001000;
                if(curr_col == 2 & curr_row == 2)
                    curr_square <= 9'b000010000;
                if(curr_col == 3 & curr_row == 2)
                    curr_square <= 9'b000100000;
                if(curr_col == 1 & curr_row == 3)
                    curr_square <= 9'b001000000;
                if(curr_col == 2 & curr_row == 3)
                    curr_square <= 9'b010000000;
                if(curr_col == 3 & curr_row == 3)
                    curr_square <= 9'b100000000;          
            end
    end
   
    // Game logic
    always @ (posedge(CLK)) begin
        // If reset or ESCAPE, clear board and set turn to Player 1
        if (reset | key_code == ESCAPE) begin
            player2_squares <= 9'b000000000;
            player1_squares <= 9'b000000000;
            curr_player <= 0;
        end
        // Place square for corresponding player when ENTER is hit
        if (!game_over)begin
            if (curr_row == 1) begin

                if (curr_col == 1 & (key_code == ENTER))
                begin
                    if (!player2_squares[1] & curr_player == 0)
                    begin
                        player1_squares[1] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[1] & curr_player == 1)
                    begin
                        player2_squares[1] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
           
                if (curr_col == 2 & (key_code == ENTER))
                begin
                    if (!player2_squares[2] & curr_player == 0)
                    begin
                        player1_squares[2] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[2] & curr_player == 1)
                    begin
                        player2_squares[2] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
           
                if (curr_col == 3 & (key_code == ENTER))
                begin
                    if (!player2_squares[3] & curr_player == 0)
                    begin
                        player1_squares[3] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[3] & curr_player == 1)
                    begin
                        player2_squares[3] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
            end
           
            if (curr_row == 2)
            begin
                if (curr_col == 1 & (key_code == ENTER))
                begin
                    if (!player2_squares[4] & curr_player == 0)
                    begin
                        player1_squares[4] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[4] & curr_player == 1)
                    begin
                        player2_squares[4] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
           
                if (curr_col == 2 & (key_code == ENTER))
                begin
                    if (!player2_squares[5] & curr_player == 0)
                    begin
                        player1_squares[5] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[5] & curr_player == 1)
                    begin
                        player2_squares[5] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
           
                if (curr_col == 3 & (key_code == ENTER))
                begin
                    if (!player2_squares[6] & curr_player == 0)
                    begin
                        player1_squares[6] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[6] & curr_player == 1)
                    begin
                        player2_squares[6] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
            end
           
            if (curr_row == 3)
            begin
                if (curr_col == 1 & (key_code == ENTER))
                begin
                    if (!player2_squares[7] & curr_player == 0)
                    begin
                        player1_squares[7] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else
                    if (!player1_squares[7] & curr_player == 1)
                    begin
                        player2_squares[7] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
           
                if (curr_col == 2 & (key_code == ENTER))
                begin
                    if (!player2_squares[8] & curr_player == 0)
                    begin
                        player1_squares[8] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else            
                    if (!player1_squares[8] & curr_player == 1)
                    begin
                        player2_squares[8] <= 1;
                        curr_player <= curr_player+1;
                    end
                end
           
                if (curr_col == 3 & (key_code == ENTER))
                begin
                    if (!player2_squares[9] & curr_player == 0)
                    begin
                        player1_squares[9] <= 1;
                        curr_player <= curr_player+1;
                    end
                    else    
                    if (!player1_squares[9] & curr_player == 1)
                    begin
                        player2_squares[9] <= 1;            
                        curr_player <= curr_player+1;
                    end
                end
            end
        end
    end
   
    reg [1:0] player_win = 0;  // stores 2b'00 if neither player won the game, stores 2'b10 if player 1 has won the game, stores 2b'11 if player 2 has won the game

    always @ (posedge(CLK))
    begin
        // removes the game over state if ESC or the restart button is pressed
        if (reset | key_code == ESCAPE)
        begin
            game_over<=0;      
            player_win <= 2'b00;
        end
       
        // resets the score only if the reset button was pressed on the board (ESC doesn't reset score)
        if (reset)
        begin
            player_1_score <= 0;
            player_2_score <= 0;
        end
       
        // checks if all the board spots are occupied, if so the game over state is set as true
        if ((9'b111111111 & (player1_squares | player2_squares)) == 9'b111111111)
            game_over <= 1;
        else
            game_over <= 0;
           
        // checks if any player has won, if so the game over state is set as true
        if(player_1_win | player_2_win)
            game_over <= 1;
       
        // if a player has won the game increments the score registers for that player
        if (player_win != 2'b10 & player_win != 2'b11)
        begin
            if (player_1_win)
            begin
                player_1_score <= player_1_score +1;
                player_win <= 2'b10;
            end
   
            if (player_2_win)
            begin
                player_2_score <= player_2_score +1;
                player_win <= 2'b11;
            end  
        end
    end
   
    // used to dim the green LED used from Arty's RGB LEDs
    reg [7:0] counter = 0;
    reg [7:0] duty_led = 8'b00000010;
   
    // dims the green led from the RGB LEDs used for displaying the score for player 2
    always @ (posedge(CLK))
    begin      
    counter <= counter + 1;
        if (counter < duty_led)
        begin
            led_score_p2 <= player_2_score;
        end
        else
        begin
            led_score_p2 <= 4'b0000;
        end
    end
 
    // displays the score for player 1 on the LEDs
    assign led_score_p1 = player_1_score;
   
endmodule