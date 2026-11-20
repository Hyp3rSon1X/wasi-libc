	.text

	.export_name	wasi_thread_start, wasi_thread_start
	.export_name	__stack_limit, __stack_limit

	.globaltype	__stack_pointer, i32
	.globaltype	__tls_base, i32
	.functype	__wasi_thread_start_C (i32, i32) -> ()

	# The lowest valid stack pointer of the current thread, exported so
	# that a runtime can detect an overflow of a thread's stack. A
	# pthread's stack comes from malloc() and has no protected guard
	# region below it, so without a limit an overflow silently runs
	# into the heap. Zero means "no limit": the main thread, whose
	# stack is laid out by the linker, keeps it at zero.
	.globaltype	__stack_limit, i32
	.hidden	__stack_limit
	.globl	__stack_limit
__stack_limit:

	.hidden	wasi_thread_start
	.globl	wasi_thread_start
	.type	wasi_thread_start,@function

wasi_thread_start:
	.functype	wasi_thread_start (i32, i32) -> ()

	# Set up the minimum C environment.
	# Note: offsetof(start_arg, stack) == 0
	# Note: offsetof(start_arg, stack_limit) == 8
	# Set the limit first, so that a runtime which checks every write
	# of __stack_pointer against __stack_limit already sees the limit
	# of this thread when the stack pointer is set.
	local.get   1  # start_arg
	i32.load    8  # stack_limit
	global.set  __stack_limit

	local.get   1  # start_arg
	i32.load    0  # stack
	global.set  __stack_pointer

	local.get   1  # start_arg
	i32.load    4  # tls_base
	global.set  __tls_base

	# Make the C function do the rest of work.
	local.get   0  # tid
	local.get   1  # start_arg
	call __wasi_thread_start_C

	# Unlock thread list. (as CLONE_CHILD_CLEARTID would do for Linux)
	#
	# Note: once we unlock the thread list, our "map_base" can be freed
	# by a joining thread. It's safe as we are in ASM and no longer use
	# our C stack or pthread_t. It's impossible to do this safely in C
	# because there is no way to tell the C compiler not to use C stack.
	i32.const   __thread_list_lock
	i32.const   0
	i32.atomic.store 0
	# As an optimization, we can check tl_lock_waiters here.
	# But for now, simply wake up unconditionally as
	# CLONE_CHILD_CLEARTID does.
	i32.const   __thread_list_lock
	i32.const   1
	memory.atomic.notify 0
	drop

	end_function
