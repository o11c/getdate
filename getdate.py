import cffi
import sysconfig


def _make_ffi():
    ffi = cffi.FFI()
    time_t_bits = 8 * sysconfig.get_config_var('SIZEOF_TIME_T')
    ffi.cdef('typedef int%d_t time_t;' % time_t_bits)
    ffi.cdef('''
        extern time_t get_date(char *, struct timeb *);
    ''')
    lib = ffi.dlopen(__file__.replace('getdate.py', 'libgetdate.so'))
    return ffi, lib
ffi, lib = _make_ffi()


class error(Exception):
    pass


def getdate(s):
    if not isinstance(s, bytes):
        s = s.encode()
    t = lib.get_date(s, ffi.NULL)
    if t == -1:
        raise error
    return t
