def copy2(src, dst):
    if os.path.isdir(dst):
        dst = os.path.join(dst, os.path.basename(src))
    try:
        if os.environ['VERBOSE'] == "--verbose":
            sys.stderr.write("   \"%s\"\n-> \"%s\"\n" % (src.replace(NDK_DIR, "$NDK"), dst.replace(NDK_DIR, "$NDK")))
        os.link(src, dst)
    except OSError as e:
        import errno
        if e.errno == errno.EEXIST:
            if not (dst.endswith("NOTICE") or dst.endswith("repo.prop")):
                import filecmp
                if not filecmp.cmp(src, dst):
                    sys.stderr.write("Warning: failed to copy files: (error: target already exists).\n   \"%s\"\n-> \"%s\"\n" % (src.replace(NDK_DIR, "$NDK"), dst.replace(NDK_DIR, "$NDK")))
            pass
        else:
            sys.stderr.write("Error: failed to copy files:\n   \"%s\"\n-> \"%s\"\n" % (src.replace(NDK_DIR, "$NDK"), dst.replace(NDK_DIR, "$NDK")))
            raise


def copytree(src, dst):
    """Recursively copy a directory tree.

    The destination directory must not already exist.
    If exception(s) occur, an Error is raised with a list of reasons.

    """
    names = os.listdir(src)
    os.makedirs(dst)
    for name in names:
        srcname = os.path.join(src, name)
        dstname = os.path.join(dst, name)
        if os.path.islink(srcname):
            linkto = os.readlink(srcname)
            copy2(linkto, dstname)
        elif os.path.isdir(srcname):
            copytree(srcname, dstname)
        else:
            copy2(srcname, dstname)


