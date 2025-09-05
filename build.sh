#! /usr/bin/zsh
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR="$HOME"/.config/quickshell/uva
cmake --build build
sudo cmake --install build
sudo chown -R $USER ~/.config/quickshell/uva
