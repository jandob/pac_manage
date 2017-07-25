# pac_manage
```
pac_manage manages your packages in a single file where you can add comments
and group your packages.

    USAGE: $0 [OPTIONS] OPERATION

    Available OPERATIONs:
        remove
            Removes all packages (pacman -Rns) that are installed but not in
            the package-list.

        update
            Update the package list. (New packages are added to the section
            'NEW_PACKAGES')

        install
            Install all missing packages.

        clean
            Removes missing packages from the list.

        update-info
            Update the extra information in the package list.
            [package]  # [repo] [(groups)] [description]
            Notes: Can only update info for installed packages. Replaces the
            whole line. If you want personal comments, add them in a line above
            the package.


    If multiple operations are given they are carried out in the order:
        1. remove
        2. update
        3. install
        4. clean
        5. update-info

    OPTIONS:
    -h --help
        Shows this help message.

    -l --list FILE_NAME
        Set the package-list file name. If the file does not exist it is
        created. (Default: '~/package-list')

    -n --no-confirm
        Don't ask for confirmations. Applys to remove and install operations.

    -d --dry-run
        Just print what would be done.


    USE CASES / EXAMPLES:
        # generate an initial package-list
        >>> $0
        # edit the list to your likings (add comments, reorder entries etc.)
        >>> vim ~/package-list
        # install new packages to your system
        >>> sudo pacman -S gvim colorgcc
        # decide you want to keep them
        # save them to your package-list (1)
        >>> $0 update
        # install some packages
        >>> sudo pacman -S cowsay ponysay
        # test the installed applications and decide you dont want to keep them
        # remove them (restore the state from (1))
        >>> $0 remove
```
