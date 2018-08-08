#! /bin/env python3

from os import listdir, path, mkdir, makedirs
from subprocess import call
from glob import glob

home_path = "/home/ymf/"
system_path = "/"
backup_mountpoint = "/mnt"
backup_drive = "Plutonium"
multimedia_dir = "Multimedia"
archive_dir = "Archive"
conf_dir = "conf/fsroot"
home_dest_dir = "home_desktop"
sys_dest_dir = "archlinux_root_desktop"

home_files = listdir(home_path)
sys_files = listdir(system_path)

backup_prefix = path.join(backup_mountpoint, backup_drive)
multimedia_backup_path = path.join(backup_prefix, multimedia_dir)
archive_backup_path = path.join(backup_prefix, archive_dir)
conf_path = path.join(home_path, conf_dir)

def rsync(src, des, exactly_same, exclude=None, cwd=None, options=None):
    args = ["-avP"]
    if exactly_same:
        args += ["--delete"]
    args += [src, des]
    if exclude:
        args += ["--exclude={0}".format(p) for p in exclude]
    if options:
        args += options
    print("executing rsync {0}".format(' '.join(args)))
    call(["rsync"] + args, cwd=cwd)

def sync_multimedia():
    rsync(path.join(home_path, "multimedia/"),
                    multimedia_backup_path,
                    exactly_same=False,
                    exclude=["music"])
def sync_home():
    des = path.join(archive_backup_path, home_dest_dir)
    try:
        mkdir(des)
    except OSError:
        pass
    rsync(home_path, des, exactly_same=True,
        exclude=[".local/share/Steam/",
                ".stack",
                ".rustup",
                ".cache",
                ".cargo",
                ".config/google-chrome"])

def sync_system():
    des = path.join(archive_backup_path, sys_dest_dir)
    try:
        mkdir(des)
    except OSError:
        pass
    rsync(system_path, des,
            exactly_same=True,
            exclude=["mnt", "tmp", "home",
                    "proc", "dev", "sys",
                    "lost+found", "srv/nfs4"])

_home_conf = [
    ".bashrc",
    ".bash_profile",
    ".manpath",
    ".dircolors",
    ".vimrc",
    ".Xresources",
    ".gtkrc-2.0",
    ".gtkrc.mine",
    ".kde4/share/config",
    ".muttrc",
    ".mutt_colors",
    ".mutt",
    ".offlineimaprc",
    ".mbsyncrc",
    ".xinitrc",
    ".xprofile",
    ".mpdconf",
    ".ncmpcpp",
    ".tmux.conf",
    ".gitconfig",
    ".asoundrc",
    ".abcde.conf",
    [".weechat", "logs", "sec.conf", "weechat.log"],
    ".ssh/config",
    ".config/fcitx/config",
    ".config/fcitx/rime/*.yaml",
    ".config/fcitx/skin/dark/fcitx_skin.conf",
    ".config/mimeapps.list",
    ".config/ranger/rc.conf",
    ".config/fish/config.fish",
    ".config/fish/functions",
    ".config/newsbeuter/config",
    ".config/newsbeuter/urls",
    ".config/newsbeuter/config",
    ".config/fontconfig/fonts.conf",
    ".config/powerline",
    ".config/nvim/",
    ".config/htop/htoprc",
    ".config/user-dirs.dirs",
    ".config/nginx/*.conf",
    ".config/awesome",
    ".config/gtk-3.0/settings.ini",
    ".config/pulse/default.pa",
    ".config/compton.conf",
    ".config/systemd/user/mpd.service",
    ".config/systemd/user/mpd_trigger.service",
    [".vim", "bundle"],
]

_sys_conf = [
#    "/etc/fstab",
    "/etc/hosts",
    "/usr/share/X11/xorg.conf.d/*",
    "/usr/src/*/.config",
    "/etc/X11/xorg.conf*",
    "/var/lib/portage",
    "/etc/portage",
    "/etc/nginx/nginx.conf",
    "/etc/systemd/system/labreverse.service",
]

def _sync_dotfiles(spec, des, cwd):
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
            print("pattern {0} does not exist, skipping"
                    .format(path.join(cwd, entry[0])))
            continue
        for f in src:
#            des_sub = re.sub('/', '_', f) + '.bak'
            des_sub = path.abspath(f)[1:]
            df = path.join(des, des_sub)
            if not path.exists(df):
                print("file {0} does not exist in the backup, skipping"
                        .format(df))
            try:
                makedirs(path.dirname(df))
            except OSError:
                pass
            if path.isdir(f):
                f = f + '/'
                df = df + '/'
            rsync(f, df, exactly_same=True, exclude=entry[1:], cwd=cwd)

def sync_dotfiles():
    _sync_dotfiles(_home_conf, conf_path, home_path)
    _sync_dotfiles(_sys_conf, conf_path, system_path)

def sync_rdotfiles():
    for src in glob(path.join(conf_path, '*')):
        rsync(src, system_path, exactly_same=False,
                options=["--no-perms", "--no-owner", "--no-group"])

if __name__ == "__main__":

    import argparse
    
    parser = argparse.ArgumentParser(description = "Backup Ted-Laptop.")
    parser.add_argument('--system', '-s', action='store_true')
    parser.add_argument('--home', '-u', action='store_true')
    parser.add_argument('--multimedia', '-m', action='store_true')
    parser.add_argument('--dotfiles', '-d', action='store_true')
    parser.add_argument('--rdotfiles', '-r', action='store_true')
    parser.add_argument('--home-path', '-U', action='store')
    parser.add_argument('--sys-path', '-S', action='store')
    parser.add_argument('--backup-mountpoint', '-B', action='store')
    parser.add_argument('--backup-drive', '-D', action='store')
    parser.add_argument('--multimedia-dir', '-M', action='store')
    parser.add_argument('--archive-dir', '-A', action='store')
    parser.add_argument('--conf-dir', '-C', action='store')
    parser.add_argument('--home-dest-dir', action='store')
    parser.add_argument('--sys-dest-dir', action='store')



    parse_ret = parser.parse_args()

    if parse_ret.home_path:
        home_path = parse_ret.home_path
    if parse_ret.sys_path:
        system_path = parse_ret.sys_path
    if parse_ret.backup_mountpoint:
        backup_mountpoint = parse_ret.backup_mountpoint
    if parse_ret.backup_drive:
        backup_drive = parse_ret.backup_drive
    if parse_ret.multimedia_dir:
        multimedia_dir = parse_ret.multimedia_dir
    if parse_ret.archive_dir:
        archive_dir = parse_ret.archive_dir
    if parse_ret.conf_dir:
        conf_dir = parse_ret.conf_dir
    if parse_ret.home_dest_dir:
        home_dest_dir = parse_ret.home_dest_dir
    if parse_ret.sys_dest_dir:
        sys_dest_dir = parse_ret.sys_dest_dir

    if parse_ret.multimedia:
        sync_multimedia()
    if parse_ret.system:
        sync_system()
    if parse_ret.home:
        sync_home()
    if parse_ret.dotfiles:
        sync_dotfiles()
    if parse_ret.rdotfiles:
        sync_rdotfiles()
