#! /bin/env python3

from os import listdir, path, mkdir
from subprocess import call

home_path = "/home/ymf/"
home_files = listdir(home_path)
root_path = "/"
root_files = listdir(root_path)

multimedia_remote_path = "/mnt/multimedia"
archive_remote_path = "/mnt/Mercury/Archive"
conf_remote_path = path.join(home_path, "conf")
home_prefix = "home_laptop"
root_prefix = "archlinux_root_laptop"

def rsync(src, des, exactly_same, exclude=[], cwd=None):
    args = ["-avP"]
    if exactly_same: args += ["--delete", "--delete-excluded"]
    args += [src, des]
    args += ["--exclude={0}".format(p) for p in exclude]
    print("executing rsync {0}".format(' '.join(args)))
    call(["rsync"] + args, cwd=cwd)

def sync_multimedia():
    rsync(path.join(home_path, "multimedia/"),
                    multimedia_remote_path,
                    exactly_same=False,
                    exclude=["music"])
def sync_home():
    des = path.join(archive_remote_path, home_prefix)
    try:
        mkdir(des)
    except OSError:
        pass
    rsync(home_path, des, exactly_same=True)

def sync_system_root():
    des = path.join(archive_remote_path, root_prefix)
    try:
        mkdir(des)
    except OSError:
        pass
    rsync(root_path, des,
            exactly_same=True,
            exclude=["mnt", "tmp", "home",
                    "proc", "dev", "sys",
                    "lost+found"])

_home_conf = [
    ".bashrc",
    ".bash_profile",
    ".vimrc",
    ".Xresources",
    ".gtkrc-2.0",
    ".kde4/share/config",
    ".muttrc",
    ".mutt_colors",
    ".mutt",
    ".offlineimaprc",
    ".mbsyncrc",
    ".xinitrc",
    ".mpdconf",
    ".ncmpcpp",
    ".tmux.conf",
    ".gitconfig",
    ".asoundrc",
    ".abcde.conf",
    ".config/fish/config.fish",
    ".config/fish/functions",
    ".config/newsbeuter/config",
    ".config/newsbeuter/urls",
    ".config/newsbeuter/config",
    ".config/fontconfig/fonts.conf",
    ".config/powerline",
    ".config/nvim/init.vim",
    ".config/htop/htoprc",
    ".config/user-dirs.dirs",
    ".config/nginx/*.conf",
    [".vim", "bundle"],
]

_sys_conf = [
    "/etc/fstab",
    "/etc/hosts",
    "/usr/share/X11/xorg.conf.d/*",
    "/usr/src/*/.config",
    "/etc/X11/xorg.conf*",
    "/var/lib/portage",
    "/etc/portage",
    "/etc/nginx/nginx.conf",
]

def _sync_dotfiles(spec, des, cwd):
    from glob import glob
    import re
    for entry in spec:
        if type(entry) is str:
            entry = [entry]
        elif type(entry) is list:
            pass
        else:
            raise "invalid spec"
        if len(entry) < 1:
            raise "invalid spec"
        src = glob(path.join(cwd, entry[0]))
        if len(src) < 1:
            print("pattern {0} does not exist, skipping".format(entry[0]))
            continue
        for f in src:
            des_sub = re.sub('/', '_', f) + '.bak'
            if path.isdir(f):
                f = f + '/'
            rsync(f, path.join(des, des_sub),
                    exactly_same=True, exclude=entry[1:], cwd=cwd)

    

def sync_dotfiles():
    _sync_dotfiles(_home_conf, conf_remote_path, home_path)
    _sync_dotfiles(_sys_conf, conf_remote_path, root_path)


if __name__ == "__main__":

    import argparse
    
    parser = argparse.ArgumentParser(description = "Backup Ted-Laptop.")
    parser.add_argument('--system', '-s', action='store_true')
    parser.add_argument('--home', '-u', action='store_true')
    parser.add_argument('--multimedia', '-m', action='store_true')
    parser.add_argument('--dotfiles', '-d', action='store_true')
    parse_ret = parser.parse_args()

    if parse_ret.multimedia:
        sync_multimedia()
    if parse_ret.system:
        sync_system_root()
    if parse_ret.home:
        sync_home()
    if parse_ret.dotfiles:
        sync_dotfiles()
