This is my repository for Gentoo packages. Contains:
 * experimental packages for Android Studio (stable, beta and canary) to be able for installing these side by side.
 * experimental packages for IntelliJ IDEA Community (uses built-in JBR 17).<br>
    Built-in version of JBR differs from standalone, because it contains some add-ons for product with which it is shipped: 
    [Some info about it](https://intellij-support.jetbrains.com/hc/en-us/community/posts/360010476759-Why-do-I-need-the-JetBrains-version-of-products-with-JBR-and-why-is-this-version-not-available-now-).<br>
    Installing built-in version doesn't mean that it have to be used for development. It can be changed in `File -> Project Structure`

This repository is available on [Gentoo repositories](https://repos.gentoo.org) list, so to use it do:
```
	$ eselect repository enable adasss
```
Of course, if you want to use my packages immediately, don't forget to do:
```
	$ emerge --sync adasss
```
If you don't want use some of my packages you can mask them in `/etc/portage/package.mask`, for example:
```
    dev-util/idea-community::adasss
```
It is possible to report bugs on [Gentoo Bugzilla](https://bugs.gentoo.org/) by starting title with (e.g.): 
```
	dev-util/android-studio-2021.2.1.14::adasss
```
But if it regards Android Studio crash, while trying to run emulator, first try to uninstall and install emulator again.

Also, if you haven't seen it yet, take a look at the [official Gentoo Wiki article on Android Studio](https://wiki.gentoo.org/wiki/Android_studio)

If you want to support my work in any way you could at least write "Hello" here: [Welcome topic](https://github.com/AdamGiergun/adasss/discussions/1)

##### Wayland

Since Android Studio Ladybug (2024.2.1) there is experimental Wayland support via -Dawt.toolkit.name=WLToolkit option. It can be added:

    via enabling experimental and wayland USE flags
    to the end of the command line invocation,
    via Help -> Edit Custom VM Options,
    directly to the ~/.config/Google/AndroidStudio<version>/studio64.vmoptions file.

It can be verified by selecting Help -> About -> Copy and Close and reviewing the text copied this way. If Wayland support is properly enabled and working, it should contain the line: Toolkit: sun.awt.wl.WLToolkit, otherwise the line may look like this: Toolkit: sun.awt.X11.XToolkit. 
