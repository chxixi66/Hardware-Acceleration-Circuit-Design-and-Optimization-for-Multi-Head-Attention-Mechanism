class data_transaction extends uvm_sequence_item;
	bit [15:0]x[64][512];
	bit [15:0]q[8][512][64];
	bit [15:0]k[8][512][64];
	bit [15:0]v[8][512][64];
	rand bit [ 4*16-1:0]x_ram[8192];
	rand bit [127:0]q_ram[8][8192];
	rand bit [127:0]k_ram[8][8192];
	rand bit [127:0]v_ram[8][8192];
	rand bit [15:0]q_bitmap_ram[8][8192];
	rand bit [15:0]k_bitmap_ram[8][8192];
	rand bit [15:0]v_bitmap_ram[8][8192];

	bit [64*64*16-1:0]attention0;
	bit [64*64*16-1:0]attention1;
	bit [64*64*16-1:0]attention2;
	bit [64*64*16-1:0]attention3;
	bit [64*64*16-1:0]attention4;
	bit [64*64*16-1:0]attention5;
	bit [64*64*16-1:0]attention6;
	bit [64*64*16-1:0]attention7;

	constraint cons_x_ram{
		foreach (x_ram[i]){
			x_ram[i][16*0+:10] == 10'd0;
			x_ram[i][16*1+:10] == 10'd0;
			x_ram[i][16*2+:10] == 10'd0;
			x_ram[i][16*3+:10] == 10'd0;
			x_ram[i][16*0+10+:5] inside {[12:18]};
			x_ram[i][16*1+10+:5] inside {[12:18]};
			x_ram[i][16*2+10+:5] inside {[12:18]};
			x_ram[i][16*3+10+:5] inside {[12:18]};
		}
	}

	constraint cons_q_ram{
		foreach (q_ram[i,j]){
			q_ram[i][j][16*0+:10]==0;
			q_ram[i][j][16*1+:10]==0;
			q_ram[i][j][16*2+:10]==0;
			q_ram[i][j][16*3+:10]==0;
			q_ram[i][j][16*4+:10]==0;
			q_ram[i][j][16*5+:10]==0;
			q_ram[i][j][16*6+:10]==0;
			q_ram[i][j][16*7+:10]==0;

			q_ram[i][j][16*0+10+:5] inside {[12:18]};
			q_ram[i][j][16*1+10+:5] inside {[12:18]};
			q_ram[i][j][16*2+10+:5] inside {[12:18]};
			q_ram[i][j][16*3+10+:5] inside {[12:18]};
			q_ram[i][j][16*4+10+:5] inside {[12:18]};
			q_ram[i][j][16*5+10+:5] inside {[12:18]};
			q_ram[i][j][16*6+10+:5] inside {[12:18]};
			q_ram[i][j][16*7+10+:5] inside {[12:18]};
		}
	}

	constraint cons_k_ram{
		foreach (k_ram[i,j]){
			k_ram[i][j][16*0+:10]==0;
			k_ram[i][j][16*1+:10]==0;
			k_ram[i][j][16*2+:10]==0;
			k_ram[i][j][16*3+:10]==0;
			k_ram[i][j][16*4+:10]==0;
			k_ram[i][j][16*5+:10]==0;
			k_ram[i][j][16*6+:10]==0;
			k_ram[i][j][16*7+:10]==0;

			k_ram[i][j][16*0+10+:5] inside{[12:18]};
			k_ram[i][j][16*1+10+:5] inside{[12:18]};
			k_ram[i][j][16*2+10+:5] inside{[12:18]};
			k_ram[i][j][16*3+10+:5] inside{[12:18]};
			k_ram[i][j][16*4+10+:5] inside{[12:18]};
			k_ram[i][j][16*5+10+:5] inside{[12:18]};
			k_ram[i][j][16*6+10+:5] inside{[12:18]};
			k_ram[i][j][16*7+10+:5] inside{[12:18]};
		}
	}
	constraint cons_v_ram{
		foreach (v_ram[i,j]){
			v_ram[i][j][16*0+:10]==0;
			v_ram[i][j][16*1+:10]==0;
			v_ram[i][j][16*2+:10]==0;
			v_ram[i][j][16*3+:10]==0;
			v_ram[i][j][16*4+:10]==0;
			v_ram[i][j][16*5+:10]==0;
			v_ram[i][j][16*6+:10]==0;
			v_ram[i][j][16*7+:10]==0;

			v_ram[i][j][16*0+10+:5] inside {[12:18]};
			v_ram[i][j][16*1+10+:5] inside {[12:18]};
			v_ram[i][j][16*2+10+:5] inside {[12:18]};
			v_ram[i][j][16*3+10+:5] inside {[12:18]};
			v_ram[i][j][16*4+10+:5] inside {[12:18]};
			v_ram[i][j][16*5+10+:5] inside {[12:18]};
			v_ram[i][j][16*6+10+:5] inside {[12:18]};
			v_ram[i][j][16*7+10+:5] inside {[12:18]};
		}
	}

	constraint cons_q_bmap{
		foreach (q_bitmap_ram[i,j]){
			q_bitmap_ram[i][j][0]+
			q_bitmap_ram[i][j][1]+
			q_bitmap_ram[i][j][2]+
			q_bitmap_ram[i][j][3]+
			q_bitmap_ram[i][j][4]+
			q_bitmap_ram[i][j][5]+
			q_bitmap_ram[i][j][6]+
			q_bitmap_ram[i][j][7]+
			q_bitmap_ram[i][j][8]+
			q_bitmap_ram[i][j][9]+
			q_bitmap_ram[i][j][10]+
			q_bitmap_ram[i][j][11]+
			q_bitmap_ram[i][j][12]+
			q_bitmap_ram[i][j][13]+
			q_bitmap_ram[i][j][14]+
			q_bitmap_ram[i][j][15] <= 8;
		}
	}

	constraint cons_k_bmap{
		foreach (k_bitmap_ram[i,j]){
			k_bitmap_ram[i][j][0]+
			k_bitmap_ram[i][j][1]+
			k_bitmap_ram[i][j][2]+
			k_bitmap_ram[i][j][3]+
			k_bitmap_ram[i][j][4]+
			k_bitmap_ram[i][j][5]+
			k_bitmap_ram[i][j][6]+
			k_bitmap_ram[i][j][7]+
			k_bitmap_ram[i][j][8]+
			k_bitmap_ram[i][j][9]+
			k_bitmap_ram[i][j][10]+
			k_bitmap_ram[i][j][11]+
			k_bitmap_ram[i][j][12]+
			k_bitmap_ram[i][j][13]+
			k_bitmap_ram[i][j][14]+
			k_bitmap_ram[i][j][15] <= 8;
		}
	}

	constraint cons_v_bmap{
		foreach (v_bitmap_ram[i,j]){
			v_bitmap_ram[i][j][0]+
			v_bitmap_ram[i][j][1]+
			v_bitmap_ram[i][j][2]+
			v_bitmap_ram[i][j][3]+
			v_bitmap_ram[i][j][4]+
			v_bitmap_ram[i][j][5]+
			v_bitmap_ram[i][j][6]+
			v_bitmap_ram[i][j][7]+
			v_bitmap_ram[i][j][8]+
			v_bitmap_ram[i][j][9]+
			v_bitmap_ram[i][j][10]+
			v_bitmap_ram[i][j][11]+
			v_bitmap_ram[i][j][12]+
			v_bitmap_ram[i][j][13]+
			v_bitmap_ram[i][j][14]+
			v_bitmap_ram[i][j][15] <= 8;
		}
	}

	
	function new(string name = "data_transaction");
		super.new(name);
		`uvm_info(get_type_name(),"new is called",UVM_LOW)
	endfunction

	function void post_randomize();
		this.print();
		`uvm_info(get_type_name(),"post_randomize is called",UVM_LOW)
		//write_to_ram();
		//write_to_file();
	endfunction

	extern function void write_to_ram();
	extern function void write_to_file();
	`uvm_object_utils_begin(data_transaction)
	`uvm_object_utils_end
endclass

function void data_transaction::write_to_ram();
	`uvm_info(get_type_name(),"begin write x q k v to ram",UVM_LOW)
	//for(int i = 0; i < 64;i++)begin
	//	for(int j = 0; j < 128; j++)begin
	//		x_ram[128*i+j] = {x[i][4*j+3],x[i][4*j+2],x[i][4*j+1],x[i][4*j+0]};
	//	end
	//end

	//for(int i = 0; i < 16;i++)begin
	//	for(int j = 0; j < 128; j++)begin
	//		q_ram[128*i+j] = 
	//		{
	//			q[4*j+3][4*i+3],q[4*j+3][4*i+2],q[4*j+3][4*i+1],q[4*j+3][4*i+0],
	//			q[4*j+2][4*i+3],q[4*j+2][4*i+2],q[4*j+2][4*i+1],q[4*j+2][4*i+0],
	//			q[4*j+1][4*i+3],q[4*j+1][4*i+2],q[4*j+1][4*i+1],q[4*j+1][4*i+0],
	//			q[4*j+0][4*i+3],q[4*j+0][4*i+2],q[4*j+0][4*i+1],q[4*j+0][4*i+0]
	//		};
	//	end
	//end

	//for(int i = 0; i < 16;i++)begin
	//	for(int j = 0; j < 128; j++)begin
	//		k_ram[128*i+j] = 
	//		{
	//			k[4*j+3][4*i+3],k[4*j+3][4*i+2],k[4*j+3][4*i+1],k[4*j+3][4*i+0],
	//			k[4*j+2][4*i+3],k[4*j+2][4*i+2],k[4*j+2][4*i+1],k[4*j+2][4*i+0],
	//			k[4*j+1][4*i+3],k[4*j+1][4*i+2],k[4*j+1][4*i+1],k[4*j+1][4*i+0],
	//			k[4*j+0][4*i+3],k[4*j+0][4*i+2],k[4*j+0][4*i+1],k[4*j+0][4*i+0]
	//		};
	//	end
	//end

	//for(int i = 0; i < 16;i++)begin
	//	for(int j = 0; j < 128; j++)begin
	//		v_ram[128*i+j] = 
	//		{
	//			v[4*j+3][4*i+3],v[4*j+3][4*i+2],v[4*j+3][4*i+1],v[4*j+3][4*i+0],
	//			v[4*j+2][4*i+3],v[4*j+2][4*i+2],v[4*j+2][4*i+1],v[4*j+2][4*i+0],
	//			v[4*j+1][4*i+3],v[4*j+1][4*i+2],v[4*j+1][4*i+1],v[4*j+1][4*i+0],
	//			v[4*j+0][4*i+3],v[4*j+0][4*i+2],v[4*j+0][4*i+1],v[4*j+0][4*i+0]
	//		};
	//	end
	//end
endfunction

function void data_transaction::write_to_file();
	integer fp;
	`uvm_info(get_type_name(),"begin write x q k v to data_file.txt",UVM_LOW)
	fp = $fopen("data_file.txt","w");
	if(fp == 0)begin
		`uvm_fatal(get_type_name(),"open data_file.txt failure,please check!!!")
	end
	//$fdisplay(fp,"x");
	//for(int i = 0; i < 64;i++)begin
	//	for(int j = 0; j < 512; j++)begin
	//		if(j == 511)begin
	//			$fdisplay(fp,"%h",x[i][j]);
	//		end
	//		else begin
	//			$fwrite(fp,"%h|",x[i][j]);
	//		end
	//	end
	//end

	//$fdisplay(fp,"q");
	//for(int i = 0; i < 512;i++)begin
	//	for(int j = 0; j < 64; j++)begin
	//		if(j == 63)begin
	//			$fdisplay(fp,"%h",q[i][j]);
	//		end
	//		else begin
	//			$fwrite(fp,"%h|",q[i][j]);
	//		end
	//	end
	//end

	//$fdisplay(fp,"k");
	//for(int i = 0; i < 512;i++)begin
	//	for(int j = 0; j < 64; j++)begin
	//		if(j == 63)begin
	//			$fdisplay(fp,"%h",k[i][j]);
	//		end
	//		else begin
	//			$fwrite(fp,"%h|",k[i][j]);
	//		end
	//	end
	//end

	//$fdisplay(fp,"v");
	//for(int i = 0; i < 512;i++)begin
	//	for(int j = 0; j < 64; j++)begin
	//		if(j == 63)begin
	//			$fdisplay(fp,"%h",v[i][j]);
	//		end
	//		else begin
	//			$fwrite(fp,"%h|",v[i][j]);
	//		end
	//	end
	//end

	$fclose(fp);
endfunction
