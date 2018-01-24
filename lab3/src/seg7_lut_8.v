module seg7_lut_8 (	oSEG0,oSEG1,oSEG2,oSEG3,oSEG4,oSEG5,oSEG6,oSEG7,iDIG );
input	[31:0]	iDIG;
output	[6:0]	oSEG0,oSEG1,oSEG2,oSEG3,oSEG4,oSEG5,oSEG6,oSEG7;

seg7_lut	u0	(	oSEG0,iDIG[3:0]		);
seg7_lut	u1	(	oSEG1,iDIG[7:4]		);
seg7_lut	u2	(	oSEG2,iDIG[11:8]	);
seg7_lut	u3	(	oSEG3,iDIG[15:12]	);
seg7_lut	u4	(	oSEG4,iDIG[19:16]	);
seg7_lut	u5	(	oSEG5,iDIG[23:20]	);
seg7_lut	u6	(	oSEG6,iDIG[27:24]	);
seg7_lut	u7	(	oSEG7,iDIG[31:28]	);

endmodule