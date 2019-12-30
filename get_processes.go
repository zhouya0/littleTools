package main

import (
	"fmt"
	"syscall"
)

func main() {
	var info syscall.Sysinfo_t
	syscall.Sysinfo(&info)
	procs := int64(info.Procs)
	fmt.Println(&procs)
}
