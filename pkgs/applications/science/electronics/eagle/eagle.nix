{
  lib,
  stdenv,
  mkDerivation,
  fetchurl,
  makeDesktopItem,
  libXrender,
  libXrandr,
  libXcursor,
  libX11,
  libXext,
  libXi,
  libxcb,
  libGL,
  glib,
  nss,
  nspr,
  expat,
  alsa-lib,
  qtbase,
  qtdeclarative,
  qtsvg,
  qtlocation,
  qtwebchannel,
  qtwebengine,
}:

let
  libPath = lib.makeLibraryPath [
    libXrender
    libXrandr
    libXcursor
    libX11
    libXext
    libXi
    libxcb
    libGL
    glib
    nss
    nspr
    expat
    alsa-lib
    qtbase
    qtdeclarative
    qtsvg
    qtlocation
    qtwebchannel
    qtwebengine
  ];
in
mkDerivation rec {
  pname = "eagle";
  version = "9.6.2";

  src = fetchurl {
    url = "https://eagle-updates.circuits.io/downloads/${
      builtins.replaceStrings [ "." ] [ "_" ] version
    }/Autodesk_EAGLE_${version}_English_Linux_64bit.tar.gz";
    sha256 = "18syygnskl286kn8aqfzzdsyzq59d2w19y1h1ynyxsnrvkyv71h0";
  };

  desktopItem = makeDesktopItem {
    name = "eagle";
    exec = "eagle";
    icon = "eagle";
    comment = "Schematic capture and PCB layout";
    desktopName = "Eagle";
    genericName = "Schematic editor";
    categories = [ "Development" ];
  };

  buildInputs = [
    libXrender
    libXrandr
    libXcursor
    libX11
    libXext
    libXi
    libxcb
    libGL
    glib
    nss
    nspr
    expat
    alsa-lib
    qtbase
    qtdeclarative
    qtsvg
    qtlocation
    qtwebchannel
    qtwebengine
  ];

  installPhase = ''
    # Extract eagle tarball
    mkdir "$out"
    tar -xzf "$src" -C "$out"

    # Install manpage
    mkdir -p "$out"/share/man/man1
    ln -s "$out"/eagle-${version}/doc/eagle.1 "$out"/share/man/man1/eagle.1

    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}:$out/eagle-${version}/lib:${lib.getLib stdenv.cc.cc}/lib" \
      "$out"/eagle-${version}/eagle

    mkdir -p "$out"/bin
    ln -s "$out"/eagle-${version}/eagle "$out"/bin/eagle

    # Remove bundled libraries that are available in nixpkgs
    # TODO: There still may be unused bundled libraries
    rm "$out"/eagle-${version}/lib/libQt5*.so.5
    rm "$out"/eagle-${version}/lib/{libxcb-*.so.*,libX*.so.*,libxshmfence.so.1}
    rm "$out"/eagle-${version}/lib/{libEGL.so.1,libglapi.so.0,libgbm.so.1}

    # No longer needed (we don't use the bundled Qt libraries)
    rm -r "$out"/eagle-${version}/libexec
    rm -r "$out"/eagle-${version}/plugins

    # Make desktop item
    mkdir -p "$out"/share/applications
    cp "$desktopItem"/share/applications/* "$out"/share/applications/
    mkdir -p "$out"/share/pixmaps
    ln -s "$out/eagle-${version}/bin/eagle-logo.png" "$out"/share/pixmaps/eagle.png
  '';

  meta = with lib; {
    description = "Schematic editor and PCB layout tool from Autodesk (formerly CadSoft)";
    homepage = "https://www.autodesk.com/products/eagle/overview";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
