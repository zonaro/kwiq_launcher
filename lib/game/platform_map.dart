Map<String, Platform> platformMap = {
  "NS - Nintendo Switch": Platform(
    extensions: ["ns", "xci"],
    matches: ["ns", "nswitch", "swt", "switch"],
    coverRatio: 0.7,
    packages: ["com.developer.nswemu", "com.switch.droidemu"],
  ),
  "NDS - Nintendo DS": Platform(
    extensions: ["nds", "slr"],
    matches: ["nintendods", "nds", "ds"],
    coverRatio: 1,
    packages: ["com.dsemu.drastic", "com.nds4droid"],
  ),
  "3DS - Nintendo 3DS": Platform(
    extensions: ["3ds", "cia"],
    matches: ["nintendo3ds", "3ds", "n3ds"],
    coverRatio: 1,
    packages: ["com.citra.citra_android", "com.citra.emulator"],
  ),
  "GB - Nintendo Game Boy": Platform(
    extensions: ["gb", "gb"],
    matches: ["gb", "gameboy"],
    coverRatio: 1,
    packages: ["it.dbtecno.pizzaboy", "com.fastemulator.gbc"],
  ),
  "GBC - Nintendo Game Boy Color": Platform(
    extensions: ["gb", "gbc"],
    matches: ["gbc", "gameboycolor"],
    coverRatio: 1,
    packages: ["it.dbtecno.pizzaboy", "com.fastemulator.gbc"],
  ),
  "GBA - Nintendo Game Boy Advance": Platform(
    extensions: ["gba"],
    matches: ["gba", "gameboyadvance"],
    coverRatio: 1,
    packages: ["com.fastemulator.gba", "com.vgba.emulator"],
  ),
  "PSP - Playstation Portable": Platform(
    extensions: ["cso", "iso", "pbp", "chd"],
    matches: ["psp", "playstationportable"],
    coverRatio: 0.7,
    packages: ["org.ppsspp.ppsspp", "com.psp.emulator"],
  ),
  "PS1 - Playstation 1": Platform(
    extensions: ["bin", "iso", "chd"],
    matches: ["ps1"],
    coverRatio: 1,
    packages: ["com.emuparadise.epsxe", "com.fpse.emulator"],
  ),
  "PS2 - Playstation 2": Platform(
    extensions: ["iso", "img", "bin", "mdf", "z", "z2", "bz2", "dump", "cso", "ima", "gz", "chd"],
    matches: ["ps2"],
    coverRatio: 0.7,
    packages: ["com.damonplay.damonps2.pro.ppsspp", "com.play.ps2emu"],
  ),
  "N64 - Nintendo 64": Platform(
    extensions: ["n64", "z64"],
    matches: ["n64", "sixtyfour", "64"],
    packages: ["org.mupen64plusae.v3.fzurita", "com.n64.emulator"],
    coverRatio: 16 / 9,
  ),
  "GC - Nintendo Game Cube": Platform(
    extensions: ["gcm", "iso"],
    matches: ["gc", "ngc", "nintendogamecube", "gamecube"],
    coverRatio: 0.7,
    packages: ["org.dolphinemu.dolphinemu", "com.gc.emulator"],
  ),
  "WII - Nintendo Wii": Platform(
    extensions: ["iso"],
    matches: ["wii", "nwii"],
    coverRatio: 0.7,
    packages: ["org.dolphinemu.dolphinemu", "com.wii.emulator"],
  ),
  "NES - Nintendo Entertainment System": Platform(
    extensions: ["nes"],
    matches: ["nes", "nintendinho", "nintendo"],
    coverRatio: 0.7,
    packages: ["com.nostalgiaemulators.neslite", "com.nes.emulator"],
  ),
  "SNES - Super Nintendo Entertainment System": Platform(
    extensions: ["sfc", "zip"],
    matches: ["snes", "super", "supernintendo"],
    packages: ["com.explusalpha.Snes9xPlus", "com.snes9x.emulator"],
    coverRatio: 1.55,
  ),
  "GEN - Sega Genesis / Mega Drive": Platform(
    extensions: ["bin", "gen", "md", "sg", "smd", "zip"],
    matches: ["gen", "segagen", "genesis", "mega", "megadrive"],
    packages: ["com.explusalpha.GenPlusDroid", "com.genesis.emulator"],
    coverRatio: 1.41,
  ),
  "DC - Sega Dreamcast": Platform(
    extensions: ["bin", "chd"],
    matches: ["dream", "dreamcast", "dc"],
    coverRatio: 1,
    packages: ["com.reicast.emulator", "com.dc.emulator"],
  ),
};

String platformName(String q) {
  for (var key in platformMap.keys) {
    if (platformMap[key]!.matches.contains(q)) {
      return key;
    }
  }
  return q;
}

class Platform {
  final List<String> extensions;
  final List<String> matches;
  final double coverRatio;
  final List<String> packages;

  Platform({
    required this.extensions,
    required this.matches,
    required this.coverRatio,
    required this.packages,
  });

  factory Platform.fromMap(Map<String, dynamic> map) {
    return Platform(
      extensions: List<String>.from(map['extensions']),
      matches: List<String>.from(map['matches']),
      coverRatio: map['coverRatio'] ?? 1.0,
      packages: List<String>.from(map['packages']),
    );
  }
}
