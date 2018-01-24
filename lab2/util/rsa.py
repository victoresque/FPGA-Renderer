#!/usr/bin/env python
from sys import argv, stdin, stdout
from struct import unpack, pack
import binascii
from string import rjust
from math import log

def mul_naive(a, b, n):
    ret = 0
    for i in range(RSA_BIT-1, -1, -1):
        ret <<= 1
        if ret >= n:
            ret -= n
        if b & (1<<i):
            ret += a
            if ret >= n:
                ret -= n
    return ret

def power_naive(a, b, n):
    a2 = a + 0
    ret = 1
    for i in range(RSA_BIT):
        if b & (1<<i):
            ret = mul_naive(ret, a2, n)
        a2 = mul_naive(a2, a2, n)
    return ret

def mont_preprocess(a, n):
    """return a*2^(RSA_BIT) % n"""
    for i in range(RSA_BIT):
        a <<= 1
        if a >= n:
            a -= n
    # or, equivalent to this
    # return (a<<RSA_BIT)%n
    return a

def mul_mont(a, b, n):
    """return a*b*2^(-RSA_BIT) % n"""
    ret = 0 # Note: ret must has RSA_BIT+1 [0,2n)
    for i in range(RSA_BIT):
        if b & (1<<i):
            ret += a
        if ret & 1:
            ret += n
        ret >>= 1
    return ret if ret<n else ret-n # [0,n) now

def power_mont(a, b, n):
    a2 = mont_preprocess(a+0, n)
    ret = 1
    # print hex(ret)
    for i in range(RSA_BIT):
        if b & (1<<i):
            ret = mul_mont(ret, a2, n)
        a2 = mul_mont(a2, a2, n)
    return ret

if __name__ == '__main__':
    assert len(argv) == 3, "Usage: {} e|d BIT".format(argv[0])
    RSA_BIT = int(argv[2])
    RSA_BIT_LOG2 = int(log(RSA_BIT, 2))

    fp_key = open('key{}.txt'.format(RSA_BIT), 'r')
    fp_key_bin = open('key{}.bin'.format(RSA_BIT), 'wb')
    str_n = rjust(fp_key.readline(), int(RSA_BIT)/4+1, '0')
    str_e = rjust(fp_key.readline(), int(RSA_BIT)/4+1, '0')
    str_d = rjust(fp_key.readline(), int(RSA_BIT)/4, '0')
    val_n = int(str_n, 16)
    val_e = int(str_e, 16)
    val_d = int(str_d, 16)
    # fp_key_bin.write(binascii.unhexlify(''.join(str_n.split())))
    # fp_key_bin.write(binascii.unhexlify(''.join(str_e.split())))
    fp_key_bin.write(binascii.unhexlify(str_n[0:int(RSA_BIT)/4]))
    fp_key_bin.write(binascii.unhexlify(str_d[0:int(RSA_BIT)/4]))

    if argv[1] == 'e':
        exponentiation = val_e
        r_chunk_size = int(RSA_BIT)/8 - 1
        w_chunk_size = int(RSA_BIT)/8
        fp_in = open('dec{}.txt'.format(RSA_BIT), 'r')
        fp_out = open('enc{}.bin'.format(RSA_BIT), 'wb')
    else:
        exponentiation = val_d
        r_chunk_size = int(RSA_BIT)/8
        w_chunk_size = int(RSA_BIT)/8 - 1
        fp_in = open('enc{}.bin'.format(RSA_BIT), 'rb')
        fp_out = open('dec{}o.txt'.format(RSA_BIT), 'w')

    while True:
        chunk = fp_in.read(r_chunk_size)
        n_read = len(chunk)
        if n_read < r_chunk_size:
            if n_read != 0:
                print "There are {} trailing bytes left (ignored).".format(n_read)
            break
        else:
            vals = unpack("{}B".format(r_chunk_size), chunk)
            msg = 0
            for val in vals:
                msg = (msg<<8) | val
            # Choose one
            #msg_new = power_naive(msg, exponentiation, val_n)
            msg_new = power_mont(msg, exponentiation, val_n)
            vals_new = map(lambda shamt: (msg_new>>shamt)&255, range((w_chunk_size-1)*8, -8, -8))
            vals_new = pack("{}B".format(w_chunk_size), *vals_new)
            fp_out.write(vals_new)

    fp_key.close()
    fp_key_bin.close()
    fp_in.close()
    fp_out.close()
