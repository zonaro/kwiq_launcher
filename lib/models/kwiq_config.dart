import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';

KwiqConfig get kwiqConfig => KwiqConfig.instance;

/// Representa a configuração do aplicativo Kwiq.
class KwiqAppConfig extends TagXml {
  KwiqAppConfig() : super.fromTagName("appConfig");

  /// Obtém ou define as categorias do aplicativo.
  Iterable<string> get categories => getValueFromNode("categories", (x) => jsonDecode(x)) ?? [];
  set categories(Iterable<string> value) => setValueForNode("categories", jsonEncode(value.distinctFlat().toList()));

  /// Obtém ou define se o aplicativo está ancorado.
  bool get isDocked => getValueFromNode("isDocked") ?? false;
  set isDocked(bool value) => setValueForNode("isDocked", value);

  /// Obtém ou define se o aplicativo é favorito.
  bool get isFavorite => getValueFromNode("isFavorite") ?? false;
  set isFavorite(bool value) => setValueForNode("isFavorite", value);

  /// Obtém ou define se o aplicativo está oculto.
  bool get isHidden => getValueFromNode("isHidden") ?? false;
  set isHidden(bool value) => setValueForNode("isHidden", value);

  /// Obtém ou define o nome do pacote do aplicativo.
  string get packageName => getValueFromNode("packageName") ?? "";
  set packageName(string value) => setValueForNode("packageName", value);
}

/// Representa a configuração principal do Kwiq.
class KwiqConfig extends TypeTag<KwiqConfig> {
  static KwiqConfig? _inst;

  /// Obtém o arquivo de configuração.
  static File get configFile => File('${appDir.path}/config.xml'.fixPath);

  /// Obtém a instância da configuração do Kwiq.
  static KwiqConfig get instance {
    if (configFile.existsSync()) {
      _inst ??= (TagXml.fromXmlString(configFile.readAsStringSync(), KwiqConfig._) ?? KwiqConfig._());
    } else {
      _inst ??= KwiqConfig._();
    }
    return _inst!..save();
  }

  KwiqConfig._();

  /// Obtém ou define a cor de destaque.
  Color get accentColor => getValueFromNode('accentColor', (x) => x.asColor) ?? NamedColors.redBrown;
  set accentColor(Color value) => setValueForNode('accentColor', value.hexadecimal);

  /// Obtém ou define os aplicativos configurados.
  Iterable<KwiqAppConfig> get apps => getTagsFromNodeList("apps", 'appConfig', KwiqAppConfig.new);
  set apps(Iterable<KwiqAppConfig> value) => setNodeList('apps', value.distinctBy((x) => x.packageName.toLowerCase()).toList());

  /// Obtém ou define a cor atual.
  Color get currentColor => getAttribute("currentColor")?.asColor ?? accentColor;
  set currentColor(Color currentColor) => setAttribute("currentColor", currentColor.hexadecimal);

  /// Obtém os papéis de parede atuais.
  Iterable<WallpaperConfig> get currentWallpapers => Get.isDarkMode ? darkWallpapers : lightWallpapers;

  /// Obtém os papéis de parede para o modo escuro.
  Iterable<WallpaperConfig> get darkWallpapers => wallpapers.where((x) => Get.context!.isLandscape ? x.landscapeDarkMode : x.portraitDarkMode);

  /// Obtém ou define o formato de data e hora.
  String get dateTimeFormat => getValueFromNode('dateTimeFormat') ?? 'HH:mm:ss';
  set dateTimeFormat(String value) => setValueForNode('dateTimeFormat', value);

  /// Obtém ou define o tempo de debounce.
  int get debounceTime => getValueFromNode('debounceTime') ?? 200;
  set debounceTime(int value) => setValueForNode('debounceTime', value);

  /// Obtém ou define os aplicativos ancorados.
  Iterable<KwiqAppConfig> get dockedApps => apps.where((x) => x.isDocked);
  set dockedApps(Iterable<KwiqAppConfig> value) {
    for (var app in apps) {
      app = getAppConfig(app.packageName);
      app.isDocked = true;
    }
  }

  /// Obtém ou define se o painel de jogos está habilitado.
  bool get enableGameDashboard => getValueFromNode('enableGameDashboard') ?? false;
  set enableGameDashboard(bool value) => setValueForNode('enableGameDashboard', value);

  /// Obtém ou define os aplicativos favoritos.
  Iterable<KwiqAppConfig> get favoriteApps => apps.where((x) => x.isFavorite);
  set favoriteApps(Iterable<KwiqAppConfig> value) {
    for (var app in apps) {
      app = getAppConfig(app.packageName);
      app.isFavorite = true;
    }
  }

  /// Obtém o número de colunas da grade.
  int get gridColumns => Get.context!.isPortrait ? portraitGridColumns : ((Get.context!.screenSize.max / Get.context!.screenSize.min) * portraitGridColumns).ceil();

  /// Obtém ou define os aplicativos ocultos.
  Iterable<KwiqAppConfig> get hiddenApps => apps.where((x) => x.isHidden);
  set hiddenApps(Iterable<KwiqAppConfig> value) {
    for (var app in apps) {
      app = getAppConfig(app.packageName);
      app.isHidden = true;
    }
  }

  /// Obtém se o painel de jogos está habilitado e o dispositivo está em modo paisagem.
  bool get isGameDashboardEnabled => enableGameDashboard && Get.context!.isLandscape;

  /// Obtém os papéis de parede para o modo claro.
  Iterable<WallpaperConfig> get lightWallpapers => wallpapers.where((x) => Get.context!.isLandscape ? x.landscapeLightMode : x.landscapeDarkMode);

  /// Obtém ou define o número máximo de resultados.
  int get maxResults => getValueFromNode('maxResults') ?? 5;
  set maxResults(int value) => setValueForNode('maxResults', value);

  /// Obtém ou define o número mínimo de caracteres.
  int get minChars => getValueFromNode('minChars') ?? 2;
  set minChars(int value) => setValueForNode('minChars', value);

  /// Obtém ou define a opacidade da sobreposição.
  double get overlayOpacity => getValueFromNode("overlayOpacity") ?? .75;
  set overlayOpacity(double value) => setValueForNode("overlayOpacity", value);

  /// Obtém ou define o número de colunas da grade em modo retrato.
  int get portraitGridColumns => getValueFromNode('gridColumns') ?? 4;
  set portraitGridColumns(int value) => setValueForNode('gridColumns', value);

  /// Obtém ou define as pesquisas recentes.
  Iterable<String> get recentSearches => getValueFromNode<Iterable<string>>('recentSearches')?.where((x) => x.isNotEmpty && x.isNotIn(tokenList) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.packageName))).distinctFlat().toList() ?? [];
  set recentSearches(Iterable<String> value) => setValueForNode('recentSearches', value.distinctFlat().toList());

  /// Obtém ou define se o tema segue o papel de parede.
  bool get themeFollowWallpaper => getValueFromNode('themeFollowWallpaper') ?? false;
  set themeFollowWallpaper(bool value) => setValueForNode('themeFollowWallpaper', value);

  /// Obtém ou define o modo de tema.
  ThemeMode get themeMode => getValueFromNode("themeMode", (x) => ThemeMode.values[x.onlyNumbersInt]) ?? ThemeMode.system;
  set themeMode(ThemeMode value) => setValueForNode('themeMode', value.index);

  /// Obtém ou define a lista de tarefas.
  Iterable<Todo> get todoList => getTagsFromNodeList("todos", "todo", Todo.new);
  set todoList(Iterable<Todo> value) => setNodeList("todos", value);

  /// Obtém ou define os aplicativos visíveis.
  Iterable<KwiqAppConfig> get visibleApps => apps.where((x) => x.isHidden == false);
  set visibleApps(Iterable<KwiqAppConfig> value) {
    for (var app in apps) {
      app = getAppConfig(app.packageName);
      app.isHidden = false;
    }
  }

  /// Obtém ou define a duração do fade do papel de parede.
  int get wallpaperFadeDuration => getValueFromNode('wallpaperFadeDuration') ?? 500;
  set wallpaperFadeDuration(int value) => setValueForNode('wallpaperFadeDuration', value);

  /// Obtém ou define o intervalo do fade do papel de parede.
  int get wallpaperInterval => getValueFromNode('wallpaperFadeInterval') ?? 10;
  set wallpaperInterval(int value) => setValueForNode('wallpaperFadeInterval', value);

  /// Obtém ou define os papéis de parede.
  Iterable<WallpaperConfig> get wallpapers => getTagsFromNodeList("wallpapers", '$WallpaperConfig'.camelCase!, WallpaperConfig.new);
  set wallpapers(Iterable<WallpaperConfig> value) => setNodeList('wallpapers', value.distinctBy((x) => generateKeyword(x.fileName)).toList());

  /// Adiciona uma categoria a um aplicativo.
  void addCategory(string packageName, string category) => setCategoriesOf(packageName, [...getCategoriesOf(packageName), category]);

  /// Adiciona uma pesquisa recente.
  void addRecentSearch(string value) {
    recentSearches = [...recentSearches, value];
  }

  /// Adiciona uma tarefa.
  void addTodo(Todo todo) => todoList = [...todoList, todo].distinctBy((x) => x.id).toList();

  /// Adiciona uma tarefa a partir de uma string.
  void addTodoString(String todo) => addTodo(Todo()..title = todo);

  /// Adiciona um papel de parede.
  void addWallpaper(WallpaperConfig wallpaper) {
    wallpapers = [...wallpapers, wallpaper].distinctBy((x) => generateKeyword(x.fileName)).toList();
    save();
  }

  /// Ancorar um aplicativo.
  void dockApp(string packageName) {
    var app = getAppConfig(packageName);
    app.isDocked = true;
    save();
  }

  /// Favoritar um aplicativo.
  void favoriteApp(string packageName) {
    var app = getAppConfig(packageName);
    app.isFavorite = true;
    save();
  }

  /// Obtém a configuração de um aplicativo.
  KwiqAppConfig getAppConfig(string packageName) {
    var cfg = apps.firstWhereOrNull((x) => x.packageName.flatEqual(packageName));
    if (cfg == null) {
      cfg = KwiqAppConfig()..packageName = packageName;
      apps = [...apps, cfg].whereNotNull().distinctBy((x) => x.packageName.toLowerCase()).toList();
      save();
    }
    return cfg;
  }

  /// Obtém as categorias de um aplicativo.
  Iterable<string> getCategoriesOf(string packageName) => apps.where((x) => x.packageName.flatEqual(packageName)).expand((x) => x.categories).distinctFlat();

  /// Obtém as categorias de um aplicativo a partir de suas informações.
  Iterable<string> getCategoriesOfApp(AppInfo app) => [app.category.name, ...getCategoriesOf(app.packageName)].distinctFlat();

  /// Obtém a configuração de um papel de parede.
  WallpaperConfig getWallpaperConfig(String fileName) {
    var cfg = wallpapers.firstWhereOrNull((x) => x.fileName.fixPath.flatEqual(fileName.fixPath));
    if (cfg == null) {
      cfg = WallpaperConfig()..fileName = fileName;
      wallpapers = [...wallpapers, cfg].distinctBy((x) => x.fileName).toList();
      save();
    }
    return cfg;
  }

  /// Oculta um aplicativo.
  void hideApp(string packageName) {
    var app = getAppConfig(packageName);
    app.isHidden = true;
    save();
  }

  /// Importa um papel de parede a partir de um arquivo.
  void importWallpaper(File file) async {
    var cfg = await WallpaperConfig.fromFile(file);
    if (cfg != null) {
      addWallpaper(cfg);
    }
  }

  /// Remove uma categoria de um aplicativo.
  void removeCategory(string packageName, string category) {
    setCategoriesOf(packageName, getCategoriesOf(packageName).whereNot((x) => x.flatEqual(category)).toList());
    save();
  }

  /// Remove uma pesquisa recente.
  void removeSearch(string value) {
    recentSearches = recentSearches.whereNot((x) => x.flatEqual(value)).toList();
    save();
  }

  /// Remove uma tarefa.
  void removeTodo(Todo todo) {
    todoList = todoList.where((x) => x.id != todo.id).toList();
    save();
  }

  /// Remove um papel de parede.
  void removeWallpaper(string fileName) {
    wallpapers = wallpapers.where((x) => x.fileName.fixPath.flatEqual(fileName.fixPath)).toList();
    save();
  }

  /// Salva a configuração no arquivo.
  Future<File> save() async {
    try {
      await configFile.parent.create(recursive: true);
      var xml = toString();
      return await configFile.writeAsString(xml);
    } catch (e) {
      consoleLog(e);
    }
    return configFile;
  }

  /// Define as categorias de um aplicativo.
  void setCategoriesOf(string packageName, Iterable<string> value) {
    var cfg = getAppConfig(packageName);
    cfg.categories = value;
    save();
  }

  /// Exibe um aplicativo.
  void showApp(string packageName) {
    var app = getAppConfig(packageName);
    app.isHidden = false;
    save();
  }

  /// Desancora um aplicativo.
  void undockApp(string packageName) {
    var app = getAppConfig(packageName);
    app.isDocked = false;
    save();
  }

  /// Desfavorita um aplicativo.
  void unfavoriteApp(string packageName) {
    var app = getAppConfig(packageName);
    app.isFavorite = false;
    save();
  }
}

/// Representa uma tarefa.
class Todo extends TypeTag<Todo> {
  /// Obtém ou define a data de criação da tarefa.
  date get created => getValueFromNode("created") ?? DateTime.now();
  set created(date value) => setValueForNode("created", value);

  /// Obtém ou define a data limite da tarefa.
  date? get deadLine => getValueFromNode("deadline");
  set deadLine(date? value) => setValueForNode("deadline", value);

  /// Obtém ou define a descrição da tarefa.
  string get description => getValueFromNode("description") ?? "";
  set description(string value) => setValueForNode("description", value);

  /// Obtém se a tarefa está concluída.
  bool get done => doneDate != null;

  /// Obtém ou define a data de conclusão da tarefa.
  date? get doneDate => getValueFromNode("doneDate");
  set doneDate(date? value) => setValueForNode("doneDate", value);

  /// Obtém o ID da tarefa.
  int get id {
    compute();
    return getAttribute("ID")?.toInt ?? hashCode;
  }

  /// Obtém o período da tarefa.
  DateRange get period => DateRange(created, doneDate ?? DateTime.now());

  /// Obtém o tempo restante para a tarefa.
  Duration? get remainingTime {
    if (done) return null;
    if (deadLine == null) return null;
    if (deadLine!.isBefore(now)) {
      return Duration.zero;
    }
    return deadLine!.difference(now);
  }

  /// Obtém ou define o título da tarefa.
  string get title => getValueFromNode("title") ?? "";
  set title(string value) => setValueForNode("title", value);

  @override
  void compute() {
    setAttribute("ID", hashCode.toString());
  }

  /// Alterna o estado de conclusão da tarefa.
  void toggle() {
    if (doneDate == null) {
      doneDate = DateTime.now();
    } else {
      doneDate = null;
    }
  }
}

/// Representa a cor de um papel de parede.
class WallpaperColor extends TypeTag<WallpaperColor> {
  /// Obtém ou define a cor.
  Color get color => getValueFromNode("color", (x) => x.asColor) ?? Colors.transparent;
  set color(Color value) => setValueForNode("color", value.hexadecimal);

  /// Obtém ou define se a cor é para o modo escuro.
  bool get darkMode => getValueFromNode("darkMode", (x) => x.asBool()) ?? false;
  set darkMode(bool value) => setValueForNode("darkMode", value.toString());

  /// Obtém ou define se a cor é para o modo claro.
  bool get lightMode => getValueFromNode("lightMode", (x) => x.asBool()) ?? false;
  set lightMode(bool value) => setValueForNode("lightMode", value.toString());

  /// Cria uma cópia da cor do papel de parede com valores opcionais alterados.
  WallpaperColor copyWith({Color? color, bool? darkMode, bool? lightMode}) {
    return WallpaperColor()
      ..color = color ?? this.color
      ..darkMode = darkMode ?? this.darkMode
      ..lightMode = lightMode ?? this.lightMode;
  }
}

/// Representa a configuração de um papel de parede.
class WallpaperConfig extends TypeTag<WallpaperConfig> {
  /// Obtém ou define a cor de destaque do papel de parede.
  Color get accentColor => getValueFromNode("color", (x) => x.asColor) ?? kwiqConfig.accentColor;
  set accentColor(Color value) => setValueForNode("color", value.hexadecimal);

  /// Obtém o alinhamento do papel de parede.
  Alignment get alignment => Alignment(portraitX, portraitY);

  /// Obtém ou define as cores do papel de parede.
  Iterable<WallpaperColor> get colors => getTagsFromNodeList("colors", "color", WallpaperColor.new);
  set colors(Iterable<WallpaperColor> value) => setNodeList("colors", value);

  /// Obtém ou define se o papel de parede é o atual.
  bool get current => getAttribute("current")?.asBool() ?? false;
  set current(bool value) => setAttribute("current", changeTo(value));

  /// Obtém se o papel de parede está desativado.
  bool get disabled => !enabled;

  /// Obtém se o papel de parede está ativado.
  bool get enabled => Get.context!.isPortrait ? portraitLightMode || portraitDarkMode : landscapeDarkMode || landscapeLightMode;

  /// Obtém o arquivo do papel de parede.
  File get file => File("${wallpaperDir.path}/$fileName".fixPath);

  /// Obtém ou define o nome do arquivo do papel de parede.
  string get fileName => getValueFromNode("fileName") ?? "";
  set fileName(string value) => setValueForNode("fileName", value.fixPath.splitAny(["/", "\\"]).last);

  /// Obtém o ajuste do papel de parede.
  BoxFit get fit {
    if (Get.context!.isPortrait) {
      if (imageIsLandscape) {
        return BoxFit.fitHeight;
      }
      if (imageIsPortrait) {
        var imageHeight = imageSize.height;
        var screenHeight = Get.context!.screenSize.height;

        var imageWidth = imageSize.width;

        while (imageHeight > screenHeight) {
          imageHeight -= 1;
          imageWidth -= 1;
        }

        while (imageHeight < screenHeight) {
          imageHeight += 1;
          imageWidth += 1;
        }

        if (imageWidth < Get.context!.screenSize.width) {
          return BoxFit.fitHeight;
        } else {
          return BoxFit.fitWidth;
        }
      }
    }

    return BoxFit.cover;
  }

  @override
  int get hashCode => fileName.hashCode;

  /// Obtém a imagem do papel de parede.
  FileImage get image => FileImage(file);

  /// Obtém o esquema de cores da imagem do papel de parede.
  Future<ColorScheme> get imageColorScheme async => await ColorScheme.fromImageProvider(provider: image);

  /// Obtém se a imagem do papel de parede é paisagem.
  bool get imageIsLandscape => imageSize.width > imageSize.height;

  /// Obtém se a imagem do papel de parede é retrato.
  bool get imageIsPortrait => imageSize.width < imageSize.height;
  /// Obtém o tamanho da imagem do papel de parede.
  Size get imageSize => ImageSizeGetter.getSize(FileInput(file));

  /// Obtém ou define se o papel de parede é paisagem.
  bool get landscape => getValueFromNode("landscape") ?? false;
  set landscape(bool value) => setValueForNode("landscape", value);

  /// Obtém o alinhamento do papel de parede em modo paisagem.
  Alignment get landscapeAlignment => Alignment(landscapeX, landscapeY);
  set landscapeAlignment(Alignment value) {
    landscapeX = value.x;
    landscapeY = value.y;
  }

  /// Obtém ou define se o papel de parede está ativado no modo escuro em paisagem.
  bool get landscapeDarkMode => getValueFromNode("darkMode", (x) => x.asBool()) ?? false;
  set landscapeDarkMode(bool value) => setValueForNode("darkMode", value.toString());

  /// Obtém ou define se o papel de parede está ativado no modo claro em paisagem.
  bool get landscapeLightMode => getValueFromNode("landscapeLightMode", (x) => x.asBool()) ?? false;
  set landscapeLightMode(bool value) => setValueForNode("landscapeLightMode", value.toString());

  /// Obtém o deslocamento do papel de parede em modo paisagem.
  Offset get landscapeOffset => Offset(landscapeX, landscapeY);
  set landscapeOffset(Offset value) {
    landscapeX = value.dx;
    landscapeY = value.dy;
  }

  /// Obtém ou define a coordenada X do papel de parede em modo paisagem.
  double get landscapeX => getValueFromNode("landscapeX") ?? 0;
  set landscapeX(double value) => setValueForNode("landscapeX", value);

  /// Obtém ou define a coordenada Y do papel de parede em modo paisagem.
  double get landscapeY => getValueFromNode("landscapeY") ?? 0;
  set landscapeY(double value) => setValueForNode("landscapeY", value);

  /// Obtém ou define a cor de sobreposição do papel de parede.
  Color? get overlayColor => getValueFromNode("overlayColor", (x) => x.asColor);
  set overlayColor(Color? value) => setValueForNode("overlayColor", value?.hexadecimal);

  /// Obtém ou define se o papel de parede é retrato.
  bool get portrait => getValueFromNode("portrait") ?? false;
  set portrait(bool value) => setValueForNode("portrait", value);

  /// Obtém o alinhamento do papel de parede em modo retrato.
  Alignment get portraitAlignment => Alignment(portraitX, portraitY);
  set portraitAlignment(Alignment value) {
    portraitX = value.x;
    portraitY = value.y;
  }

  /// Obtém ou define se o papel de parede está ativado no modo escuro em retrato.
  bool get portraitDarkMode => getValueFromNode("portraitDarkMode", (x) => x.asBool()) ?? false;
  set portraitDarkMode(bool value) => setValueForNode("portraitDarkMode", value.toString());

  /// Obtém ou define se o papel de parede está ativado no modo claro em retrato.
  bool get portraitLightMode => getValueFromNode("portraitLightMode", (x) => x.asBool()) ?? false;
  set portraitLightMode(bool value) => setValueForNode("portraitLightMode", value.toString());

  /// Obtém ou define a coordenada X do papel de parede em modo retrato.
  double get portraitX => getValueFromNode("portraitX") ?? 0;
  set portraitX(double value) => setValueForNode("portraitX", value);

  /// Obtém ou define a coordenada Y do papel de parede em modo retrato.
  double get portraitY => getValueFromNode("portraitY") ?? 0;
  set portraitY(double value) => setValueForNode("portraitY", value);

  /// Obtém ou define a URL do papel de parede.
  Uri? get url => getValueFromNode<Uri?>("url", (x) => Uri.tryParse(x));
  set url(Uri? value) => setValueForNode("url", value?.toString());

  @override
  bool operator ==(Object other) {
    if (other is WallpaperConfig) {
      return fileName == other.fileName;
    } else {
      return fileName.flatEqual(other);
    }
  }

  /// Adiciona uma cor ao papel de parede.
  void addColor(dynamic color) {
    if (color is Color) {
      color = WallpaperColor()..color = color;
    }

    if (color is WallpaperColor) {
      colors = [...colors, color].distinctBy((x) => x.color).toList();
    }
    addColor(changeTo<Color>(color));
  }

  /// Exclui o papel de parede.
  Future<void> delete() async {
    if (await file.exists()) {
      await file.delete();
    }
    kwiqConfig.removeWallpaper(fileName);
  }

  /// Remove uma cor do papel de parede.
  void removeColor(dynamic color) {
    if (color is WallpaperColor) {
      color = color.color;
    } else {
      color = changeTo<Color>(color);
    }

    if (color is Color) {
      colors = colors.where((x) => x.color != color).toList();
    }
  }

  /// Define a cor de destaque do papel de parede.
  Future<void> setAccentColor() async {
    accentColor = (await ColorScheme.fromImageProvider(provider: image)).primary;
  }

  /// Cria uma configuração de papel de parede a partir de um arquivo.
  static Future<WallpaperConfig?> fromFile(File file) async {
    var cfg = WallpaperConfig()..fileName = file.path.splitAny(["/", "\\"]).last;
    if (file.existsSync()) {
      if (!file.parent.path.fixPath.flatEqual(wallpaperDir.path)) {
        await file.copyTo(wallpaperDir);
      }
      cfg.accentColor = (await ColorScheme.fromImageProvider(provider: FileImage(file))).primary;
      kwiqConfig.addWallpaper(cfg);
      return cfg;
    }
    return null;
  }
}
