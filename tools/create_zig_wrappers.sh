for tool in ar cc c++ dlltool lib ranlib objcopy ld.lld; do
	ln -snf ../zig_wrapper "wrappers/zig/${tool}"
done
