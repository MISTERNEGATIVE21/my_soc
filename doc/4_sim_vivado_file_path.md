
# 有效路径
导入文件的时候，需要注意 rom.bin等文件的位置
1. 放在 pattern目录下，无效
2. 放在 c/../.../ 目前下，无效 (在 vivado cmd 界面下 pwd 获取到的目录)
3. 放在 vivado 工程路径下才有效。 /vivado_prj/sim_1/behav/xsim

# 拷贝
然后可以通过makefile 拷贝， or 相对路径的方式索引到文件