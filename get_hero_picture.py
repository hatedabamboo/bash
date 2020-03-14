#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import random

hash = random.getrandbits(128)

def get_pic(params, filename):
    pic = str('/tmp/' + filename + '.png')
    r = requests.get('https://homm3.loskir.ru/', params=params)
    if r.status_code == 200:
        with open(pic, 'wb') as f:
            for chunk in r.iter_content(chunk_size=100000):
                f.write(chunk)

# params = {'text':'text', 'color':'red/blue/gray/green/etc', 'show_ok':'true/false', 'show_cancel':'true/false'}

text = input('Enter text you want to heroise: ')

params = {'text':text}

get_pic(params=params, filename=str(hash))
