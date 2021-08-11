#!/usr/bin/python3


import sys, random, string


def die():
    message = """Usage:
    {} ldp <length>
    l — letters included
    d — digits included
    p — punctuation included""".format(sys.argv[0])
    sys.exit(message)


def pass_gen():
    l = string.ascii_letters
    d = string.digits
    p = string.punctuation
    params = ""
    if len(sys.argv) > 2:
        if sys.argv[1].isalpha():
            length = int(sys.argv[2])
            if 'l' in sys.argv[1]:
                params = params + l
            if 'd' in sys.argv[1]:
                params = params + d
            if 'p' in sys.argv[1]:
                params = params + p
            password = ''.join(random.choices(params, k=length))
            print(password)
        else:
            die()
    else:
        die()


pass_gen()
