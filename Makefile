cpu_tb.lxt: cpu_tb
	./cpu_tb -lxt2

cpu_tb: cpu.v cpu_tb.v
	iverilog -o cpu_tb cpu.v cpu_tb.v

test.lxt: test_tb
	./test_tb -lxt2

test_tb: test_tb.v test.v
	iverilog -o test_tb test_tb.v test.v

video_tb.lxt: video_tb
	./video_tb -lxt2

video_tb: video.v video_tb.v
	iverilog -o video_tb video.v video_tb.v
