#! /bin/env python

from os import listdir, path, mkdir
from subprocess import call

home_path = "/home/ymf"
home_files = listdir(home_path)
root_path = "/"
root_files = listdir(root_path)

multimedia_external_path = "/mnt/multimedia"
assets_external_path = "/mnt/archive"
home_prefix = "gentoo_ymf"
root_prefix = "gentoo_root"
vmware_prefix = "vmware"

def sync_files(src, des, exactly_same):
    args = ["-av"]
    if exactly_same: args += ["--delete"]
    args += [src, des]

    call(["rsync"] + args)

def sync_with_external_disk(src, des, exclude = [], exactly_same = False):
    if len(exclude):
        for filename in listdir(src):
            print filename
            if filename in exclude: continue
            sync_files(path.join(src, filename), path.join(des), exactly_same)
    else:
        sync_files(src, des, exactly_same)

def sync_multimedia():
    sync_with_external_disk(path.join(home_path, "multimedia/"), 
                            multimedia_external_path,
                            exclude = ["music"])
def sync_vmware():
    sync_with_external_disk(path.join(home_path, "vmware/"),
                            path.join(assets_external_path, vmware_prefix),
                            exactly_same = False)
def sync_other_home_files():
    des = path.join(assets_external_path, home_prefix)
    try:
        mkdir(des)
    except OSError:
        pass
    sync_with_external_disk(home_path, des,
            exclude = ["multimedia", "vmware"],
            exactly_same = True)

def sync_system_root():
    des = path.join(assets_external_path, root_prefix)
    try:
        mkdir(des)
    except OSError:
        pass
    sync_with_external_disk(root_path, des,
            exclude = ["mnt", "tmp", "home", "proc", "dev", "sys", "lost+found"],
            exactly_same = True)

if __name__ == "__main__":

    import argparse
    
    parser = argparse.ArgumentParser(description = "Backup the stuff on Ted-Laptop.")
    parser.add_argument('--system', '-s', action='store_true')
    parser.add_argument('--home', '-u', action='store_true')
    parser.add_argument('--multimedia', '-m', action='store_true')
    parser.add_argument('--vmware', '-vm', action='store_true')
    parse_ret = parser.parse_args()

    if parse_ret.multimedia:
        sync_multimedia()
    if parse_ret.vmware:
        sync_vmware()
    if parse_ret.system:
        sync_system_root()
    if parse_ret.home:
        sync_other_home_files()
