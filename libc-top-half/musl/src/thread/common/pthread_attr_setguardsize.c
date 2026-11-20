#include "pthread_impl.h"

int pthread_attr_setguardsize(pthread_attr_t *a, size_t size)
{
#if defined(__wasilibc_unmodified_upstream) || defined(_REENTRANT)
	/* On wasi-threads the guard is not protected (there is no
	 * mprotect): it is slack below the exported __stack_limit of the
	 * thread, see wasi_thread_start.s. */
	if (size > SIZE_MAX/8) return EINVAL;
#else
	/* WASI doesn't have memory protection required for stack guards. */
	if (size > 0) return EINVAL;
#endif
	a->_a_guardsize = size;
	return 0;
}
