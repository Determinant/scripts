#! /bin/env python

from os.path import join, isdir, basename, exists, dirname
from os import listdir, mkdir, rename

def recitfy_fat_filename(name):
    rname = ""
    for ch in name:
        rname += " " if ch in "*/:<>?[]|" else ch
    return rname

def check_out_file(path):
    fname = basename(path)
    rct = recitfy_fat_filename(fname)
    if rct != fname:
        rename(path,join(dirname(path), rct))

def walk_directory(path):
    dir_list = listdir(path)
    for f in dir_list:
        fpath = join(path, f)
        if isdir(fpath):
            walk_directory(fpath)
        else:
            check_out_file(fpath)

from sys import argv

if len(argv) < 2: exit()

walk_directory(argv[1])
