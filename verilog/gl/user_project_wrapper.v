// SPDX-FileCopyrightText: 2026 Direct-RF Transceiver Project
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: Apache-2.0
module user_project_wrapper (user_clock2,
    vccd1,
    vccd2,
    vdda1,
    vdda2,
    vssa1,
    vssa2,
    vssd1,
    vssd2,
    wb_clk_i,
    wb_rst_i,
    wbs_ack_o,
    wbs_cyc_i,
    wbs_stb_i,
    wbs_we_i,
    analog_io,
    io_in,
    io_oeb,
    io_out,
    la_data_in,
    la_data_out,
    la_oenb,
    user_irq,
    wbs_adr_i,
    wbs_dat_i,
    wbs_dat_o,
    wbs_sel_i);
 input user_clock2;
 input vccd1;
 input vccd2;
 input vdda1;
 input vdda2;
 input vssa1;
 input vssa2;
 input vssd1;
 input vssd2;
 input wb_clk_i;
 input wb_rst_i;
 output wbs_ack_o;
 input wbs_cyc_i;
 input wbs_stb_i;
 input wbs_we_i;
 inout [28:0] analog_io;
 input [37:0] io_in;
 output [37:0] io_oeb;
 output [37:0] io_out;
 input [127:0] la_data_in;
 output [127:0] la_data_out;
 input [127:0] la_oenb;
 output [2:0] user_irq;
 input [31:0] wbs_adr_i;
 input [31:0] wbs_dat_i;
 output [31:0] wbs_dat_o;
 input [3:0] wbs_sel_i;

 wire chip_ready_out;

 phase_099_top_integration mprj (.VGND(vssd1),
    .VPWR(vccd1),
    .chip_ready_out(chip_ready_out),
    .clk_2p4g(user_clock2),
    .clk_dsp(wb_clk_i),
    .rst_n(la_data_in[0]),
    .module_status_flags_out({la_data_out[97],
    la_data_out[96],
    la_data_out[95],
    la_data_out[94],
    la_data_out[93],
    la_data_out[92],
    la_data_out[91],
    la_data_out[90],
    la_data_out[89],
    la_data_out[88],
    la_data_out[87],
    la_data_out[86],
    la_data_out[85],
    la_data_out[84],
    la_data_out[83],
    la_data_out[82],
    la_data_out[81],
    la_data_out[80],
    la_data_out[79],
    la_data_out[78],
    la_data_out[77],
    la_data_out[76],
    la_data_out[75],
    la_data_out[74],
    la_data_out[73],
    la_data_out[72],
    la_data_out[71],
    la_data_out[70],
    la_data_out[69],
    la_data_out[68],
    la_data_out[67],
    la_data_out[66],
    la_data_out[65],
    la_data_out[64],
    la_data_out[63],
    la_data_out[62],
    la_data_out[61],
    la_data_out[60],
    la_data_out[59],
    la_data_out[58],
    la_data_out[57],
    la_data_out[56],
    la_data_out[55],
    la_data_out[54],
    la_data_out[53],
    la_data_out[52],
    la_data_out[51],
    la_data_out[50],
    la_data_out[49],
    la_data_out[48],
    la_data_out[47],
    la_data_out[46],
    la_data_out[45],
    la_data_out[44],
    la_data_out[43],
    la_data_out[42],
    la_data_out[41],
    la_data_out[40],
    la_data_out[39],
    la_data_out[38],
    la_data_out[37],
    la_data_out[36],
    la_data_out[35],
    la_data_out[34],
    la_data_out[33],
    la_data_out[32],
    la_data_out[31],
    la_data_out[30],
    la_data_out[29],
    la_data_out[28],
    la_data_out[27],
    la_data_out[26],
    la_data_out[25],
    la_data_out[24],
    la_data_out[23],
    la_data_out[22],
    la_data_out[21],
    la_data_out[20],
    la_data_out[19],
    la_data_out[18],
    la_data_out[17],
    la_data_out[16],
    la_data_out[15],
    la_data_out[14],
    la_data_out[13],
    la_data_out[12],
    la_data_out[11],
    la_data_out[10],
    la_data_out[9],
    la_data_out[8],
    la_data_out[7],
    la_data_out[6],
    la_data_out[5],
    io_out[37],
    io_out[36],
    io_out[35],
    io_out[34],
    io_out[33]}),
    .rf_adc_i_in({io_in[15],
    io_in[14],
    io_in[13],
    io_in[12],
    io_in[11],
    io_in[10],
    io_in[9],
    io_in[8],
    io_in[7],
    io_in[6],
    io_in[5],
    io_in[4],
    io_in[3],
    io_in[2],
    io_in[1],
    io_in[0]}),
    .rf_adc_q_in({io_in[31],
    io_in[30],
    io_in[29],
    io_in[28],
    io_in[27],
    io_in[26],
    io_in[25],
    io_in[24],
    io_in[23],
    io_in[22],
    io_in[21],
    io_in[20],
    io_in[19],
    io_in[18],
    io_in[17],
    io_in[16]}),
    .rf_dac_i_out({io_out[15],
    io_out[14],
    io_out[13],
    io_out[12],
    io_out[11],
    io_out[10],
    io_out[9],
    io_out[8],
    io_out[7],
    io_out[6],
    io_out[5],
    io_out[4],
    io_out[3],
    io_out[2],
    io_out[1],
    io_out[0]}),
    .rf_dac_q_out({io_out[31],
    io_out[30],
    io_out[29],
    io_out[28],
    io_out[27],
    io_out[26],
    io_out[25],
    io_out[24],
    io_out[23],
    io_out[22],
    io_out[21],
    io_out[20],
    io_out[19],
    io_out[18],
    io_out[17],
    io_out[16]}));
 assign io_oeb[0] = la_oenb[0];
 assign io_oeb[10] = la_oenb[10];
 assign io_oeb[11] = la_oenb[11];
 assign io_oeb[12] = la_oenb[12];
 assign io_oeb[13] = la_oenb[13];
 assign io_oeb[14] = la_oenb[14];
 assign io_oeb[15] = la_oenb[15];
 assign io_oeb[16] = la_oenb[16];
 assign io_oeb[17] = la_oenb[17];
 assign io_oeb[18] = la_oenb[18];
 assign io_oeb[19] = la_oenb[19];
 assign io_oeb[1] = la_oenb[1];
 assign io_oeb[20] = la_oenb[20];
 assign io_oeb[21] = la_oenb[21];
 assign io_oeb[22] = la_oenb[22];
 assign io_oeb[23] = la_oenb[23];
 assign io_oeb[24] = la_oenb[24];
 assign io_oeb[25] = la_oenb[25];
 assign io_oeb[26] = la_oenb[26];
 assign io_oeb[27] = la_oenb[27];
 assign io_oeb[28] = la_oenb[28];
 assign io_oeb[29] = la_oenb[29];
 assign io_oeb[2] = la_oenb[2];
 assign io_oeb[30] = la_oenb[30];
 assign io_oeb[31] = la_oenb[31];
 assign io_oeb[32] = la_oenb[32];
 assign io_oeb[33] = la_oenb[33];
 assign io_oeb[34] = la_oenb[34];
 assign io_oeb[35] = la_oenb[35];
 assign io_oeb[36] = la_oenb[36];
 assign io_oeb[37] = la_oenb[37];
 assign io_oeb[3] = la_oenb[3];
 assign io_oeb[4] = la_oenb[4];
 assign io_oeb[5] = la_oenb[5];
 assign io_oeb[6] = la_oenb[6];
 assign io_oeb[7] = la_oenb[7];
 assign io_oeb[8] = la_oenb[8];
 assign io_oeb[9] = la_oenb[9];
 assign io_out[32] = chip_ready_out;
 assign la_data_out[0] = io_out[33];
 assign la_data_out[100] = la_data_in[2];
 assign la_data_out[101] = la_data_in[3];
 assign la_data_out[102] = la_data_in[4];
 assign la_data_out[103] = la_data_in[5];
 assign la_data_out[104] = la_data_in[6];
 assign la_data_out[105] = la_data_in[7];
 assign la_data_out[106] = la_data_in[8];
 assign la_data_out[107] = la_data_in[9];
 assign la_data_out[108] = la_data_in[10];
 assign la_data_out[109] = la_data_in[11];
 assign la_data_out[110] = la_data_in[12];
 assign la_data_out[111] = la_data_in[13];
 assign la_data_out[112] = la_data_in[14];
 assign la_data_out[113] = la_data_in[15];
 assign la_data_out[114] = la_data_in[16];
 assign la_data_out[115] = la_data_in[17];
 assign la_data_out[116] = la_data_in[18];
 assign la_data_out[117] = la_data_in[19];
 assign la_data_out[118] = la_data_in[20];
 assign la_data_out[119] = la_data_in[21];
 assign la_data_out[120] = la_data_in[22];
 assign la_data_out[121] = la_data_in[23];
 assign la_data_out[122] = la_data_in[24];
 assign la_data_out[123] = la_data_in[25];
 assign la_data_out[124] = la_data_in[26];
 assign la_data_out[125] = la_data_in[27];
 assign la_data_out[126] = la_data_in[28];
 assign la_data_out[127] = la_data_in[29];
 assign la_data_out[1] = io_out[34];
 assign la_data_out[2] = io_out[35];
 assign la_data_out[3] = io_out[36];
 assign la_data_out[4] = io_out[37];
 assign la_data_out[98] = la_data_in[0];
 assign la_data_out[99] = la_data_in[1];
 assign user_irq[0] = la_data_out[32];
 assign user_irq[1] = la_data_out[33];
 assign user_irq[2] = la_data_out[34];
 assign wbs_ack_o = wbs_stb_i;
 assign wbs_dat_o[0] = io_out[33];
 assign wbs_dat_o[10] = la_data_out[10];
 assign wbs_dat_o[11] = la_data_out[11];
 assign wbs_dat_o[12] = la_data_out[12];
 assign wbs_dat_o[13] = la_data_out[13];
 assign wbs_dat_o[14] = la_data_out[14];
 assign wbs_dat_o[15] = la_data_out[15];
 assign wbs_dat_o[16] = la_data_out[16];
 assign wbs_dat_o[17] = la_data_out[17];
 assign wbs_dat_o[18] = la_data_out[18];
 assign wbs_dat_o[19] = la_data_out[19];
 assign wbs_dat_o[1] = io_out[34];
 assign wbs_dat_o[20] = la_data_out[20];
 assign wbs_dat_o[21] = la_data_out[21];
 assign wbs_dat_o[22] = la_data_out[22];
 assign wbs_dat_o[23] = la_data_out[23];
 assign wbs_dat_o[24] = la_data_out[24];
 assign wbs_dat_o[25] = la_data_out[25];
 assign wbs_dat_o[26] = la_data_out[26];
 assign wbs_dat_o[27] = la_data_out[27];
 assign wbs_dat_o[28] = la_data_out[28];
 assign wbs_dat_o[29] = la_data_out[29];
 assign wbs_dat_o[2] = io_out[35];
 assign wbs_dat_o[30] = la_data_out[30];
 assign wbs_dat_o[31] = la_data_out[31];
 assign wbs_dat_o[3] = io_out[36];
 assign wbs_dat_o[4] = io_out[37];
 assign wbs_dat_o[5] = la_data_out[5];
 assign wbs_dat_o[6] = la_data_out[6];
 assign wbs_dat_o[7] = la_data_out[7];
 assign wbs_dat_o[8] = la_data_out[8];
 assign wbs_dat_o[9] = la_data_out[9];
endmodule
