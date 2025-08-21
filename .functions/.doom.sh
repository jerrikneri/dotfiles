cdoom() {
  cd ~/code/doom/chocolate-doom/build
  cmake .. -DCMAKE_BUILD_TYPE=Debug
  make -j$(nproc)

  ./src/chocolate-doom -iwad ~/code/doom/wads/DOOM.WAD
}
