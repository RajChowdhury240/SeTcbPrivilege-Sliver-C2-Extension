package main

/*
#include <stdlib.h>
#include <stdint.h>

typedef int (*goCallback)(const char*, int);

static int callCallback(void* cb, const char* msg, int len) {
	return ((goCallback)cb)(msg, len);
}
*/
import "C"
import (
	"fmt"
	"unsafe"
)

//export entrypoint
func entrypoint(argsBuffer *C.char, bufferSize C.uint32_t, cb unsafe.Pointer) C.int {
	args := C.GoStringN(argsBuffer, C.int(bufferSize))

	logf = func(format string, a ...interface{}) {
		msg := fmt.Sprintf(format, a...)
		cMsg := C.CString(msg)
		C.callCallback(cb, cMsg, C.int(len(msg)))
		C.free(unsafe.Pointer(cMsg))
	}

	if err := executeTcb(args); err != nil {
		logf("[x] %v.\n", err)
	}
	return 0
}


