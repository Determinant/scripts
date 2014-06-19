#! /bin/env python
from os.path import join, isdir, basename, exists
from os import listdir, mkdir
from subprocess import PIPE, Popen
from sys import stdout
from mutagen.flac import FLAC
import sys
import re
import errno

def convert(stderr_out, cmdline1=None, cmdline2=None):
    """
    executes audio conversion pipeline command
    """
    if cmdline1 is not None and cmdline2 is not None:
        print cmdline1
        p1 = Popen(cmdline1, stdout=PIPE, stderr=stderr_out)
        print p1.stdout
        p2 = Popen(cmdline2, stdin=p1.stdout, stdout=PIPE, stderr=stderr_out)
        p2.communicate()
        return not p2.returncode
    elif cmdline1 is not None and cmdline2 is None:
        p1 = Popen(cmdline1, stdout=PIPE, stderr=stderr_out)
        p1.communicate()
        return not p1.returncode
    else:
        raise SystemExit("Error: unexpected arguments on: convert()")
def convert_to_aac(path, fname, stderr_out, outdir):
    """
    converts input track to MPEG-1 Layer III format (aka MP3)
    """
    outdir = outdir or './'
    cmd1 = ["avconv", "-y", "-i", path, "-f", "wav", "-"]
    cmd2 = ["neroAacEnc", "-cbr", "192000", "-ignorelength", "-if", "-", "-of", join(outdir, fname + ".mp4")]
    return convert(stderr_out, cmdline1=cmd1, cmdline2=cmd2)

std_meta = {"title", "artist", "year", "album", "genre",
            "track", "totaltracks", "disc", "totaldics",
            "url", "copyright", "comment", "lyrics",
            "credits", "rating", "label", "composer",
            "isrc", "mood", "tempo"}

def _rectify(s):
    s = str.lower(s)
    if s == "tracknumber": s = "track"
    if s == "tracktotal": s = "totaltracks"
    if s in std_meta:
        return "-meta:" + s
    else:
        return "-meta-user:" + s

def copy_id3tag(src, des):
    from subprocess import call

    f = FLAC(src)
    args = ["neroAacTag", des]
    for key in f.keys():
        args.extend([_rectify(key) + "=" + f[key][0],])
    print args
    call(args)

patt = re.compile("(.*)\.flac")

def touch_dir(path):
    try:
        mkdir(path)
    except OSError as e:
        if e.errno != errno.EEXIST: raise

def check_out_file(src_fpath, des_path):
    global patt
    fname = basename(src_fpath)
    m = patt.match(fname)
    if m:
        print "found file:" + src_fpath + " should be copied to " + des_path
        des_fpath = join(des_path, m.group(1) + ".mp4")
        if not exists(des_fpath): 
            convert_to_aac(src_fpath, m.group(1), None, des_path)
        copy_id3tag(src_fpath, des_fpath)

def walk_directory(src_path, des_path):
    dir_list = listdir(src_path)
    for f in dir_list:
        src_fpath = join(src_path, f)
        if isdir(src_fpath):
            des_fpath = join(des_path, f)
            touch_dir(des_fpath)
            walk_directory(src_fpath, des_fpath)
        else:
            check_out_file(src_fpath, des_path)

if len(sys.argv) < 2: exit()

src_path = sys.argv[1]
des_path = sys.argv[2]

touch_dir(des_path)
walk_directory(src_path, des_path)
