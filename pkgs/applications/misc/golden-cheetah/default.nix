{ lib, fetchFromGitHub, fetchpatch, mkDerivation
, qtbase, qtsvg, qtserialport, qtwebengine, qtmultimedia, qttools
, qtconnectivity, qtcharts, libusb-compat-0_1, gsl, blas
, bison, flex, zlib, qmake, makeDesktopItem, wrapQtAppsHook
}:

let
  desktopItem = makeDesktopItem {
    name = "goldencheetah";
    exec = "GoldenCheetah";
    icon = "goldencheetah";
    desktopName = "GoldenCheetah";
    genericName = "GoldenCheetah";
    comment = "Performance software for cyclists, runners and triathletes";
    categories = [ "Utility" ];
  };
in mkDerivation rec {
  pname = "golden-cheetah";
  version = "3.6-RC4";

  src = fetchFromGitHub {
    owner = "GoldenCheetah";
    repo = "GoldenCheetah";
    rev = "refs/tags/v${version}";
    hash = "sha256-2cwxsfy4Zc9fF3fe6QcZp3LPd2yWw2rDlYrK/QGiJYw=";
  };

  buildInputs = [
    qtbase
    qtsvg
    qtserialport
    qtwebengine
    qtmultimedia
    qttools
    zlib
    qtconnectivity
    qtcharts
    libusb-compat-0_1
    gsl
    blas
  ];
  nativeBuildInputs = [ flex wrapQtAppsHook qmake bison ];

  patches = [
    # allow building with bison 3.7
    # Included in https://github.com/GoldenCheetah/GoldenCheetah/pull/3590,
    # which is periodically rebased but pre 3.6 release, as it'll break other CI systems
    ./0001-Fix-building-with-bison-3.7.patch
  ];

  NIX_LDFLAGS = "-lz -lgsl -lblas";

  qtWrapperArgs = [ "--prefix" "LD_LIBRARY_PATH" ":" "${zlib.out}/lib" ];

  preConfigure = ''
    cp src/gcconfig.pri.in src/gcconfig.pri
    cp qwt/qwtconfig.pri.in qwt/qwtconfig.pri
    sed -i 's,^#QMAKE_LRELEASE.*,QMAKE_LRELEASE = ${qttools.dev}/bin/lrelease,' src/gcconfig.pri
    sed -i 's,^#LIBUSB_INSTALL.*,LIBUSB_INSTALL = ${libusb-compat-0_1},' src/gcconfig.pri
    sed -i 's,^#LIBUSB_INCLUDE.*,LIBUSB_INCLUDE = ${libusb-compat-0_1.dev}/include,' src/gcconfig.pri
    sed -i 's,^#LIBUSB_LIBS.*,LIBUSB_LIBS = -L${libusb-compat-0_1}/lib -lusb,' src/gcconfig.pri
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp src/GoldenCheetah $out/bin
    install -Dm644 "${desktopItem}/share/applications/"* -t $out/share/applications/
    install -Dm644 src/Resources/images/gc.png $out/share/pixmaps/goldencheetah.png

    runHook postInstall
  '';

  meta = with lib; {
    description = "Performance software for cyclists, runners and triathletes";
    platforms = platforms.linux;
    maintainers = with maintainers; [ adamcstephens ];
    license = licenses.gpl2Plus;
  };
}
