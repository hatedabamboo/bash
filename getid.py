#!/usr/bin/python3

import vk
import sys
import getid_config


session = vk.Session()
api = vk.API(session, v = 5.102)
token = getid_config.token


if len(sys.argv) == 1:
    print('Error: missing short name.')
else:
    userid = sys.argv[1]
    r = api.users.get(access_token = token, user_ids = userid)
    id = r[0]['id']
    print(id)
