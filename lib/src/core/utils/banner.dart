import 'package:characters/characters.dart';

void main() {
  Banner.show();
}

/// Flutter Architecture CLI Tool — skyBlue Edition Banner
class Banner {
  static const String version = '1.0.0';
  static const String developer = 'Rakibur Rahman';
  static const String githubUrl = 'https://github.com/rakibur557/flarch_cli';

  // TrueColor helper
  static String rgb(int r, int g, int b) => '\x1B[38;2;$r;$g;${b}m';

  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const underlineOn = '\x1B[4m';
  static const underlineOff = '\x1B[24m';

  static void show() {
    final skyBlue = rgb(135, 206, 250); // Section titles
    final white = rgb(255, 255, 255);
    const int boxWidth = 63; // consistent frame width

    // Helper: strip ANSI and pad properly
    String stripAnsi(String input) => input.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
    String pad(String input, [int width = boxWidth - 4]) {
      final len = stripAnsi(input).characters.length;
      return input + ' ' * (width - len);
    }

    // Block logo (FLARCH)
    final flarchLogo = [
      '  ███████╗██╗      █████╗ ██████╗  ██████╗██╗  ██╗   ',
      '  ██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝██║  ██║   ',
      '  █████╗  ██║     ███████║██████╔╝██║     ███████║   ',
      '  ██╔══╝  ██║     ██╔══██║██╔══██╗██║     ██╔══██║   ',
      '  ██║     ███████╗██║  ██║██║  ██║╚██████╗██║  ██║   ',
      '  ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ',
    ];

    // Print top border
    print('$skyBlue╔${'═' * (boxWidth - 2)}╗$reset');

    // Logo lines
    for (final line in flarchLogo) {
      print('$skyBlue║$reset ${pad('$skyBlue$line$reset')}$skyBlue║$reset');
    }

    // Spacer and title
    print('$skyBlue║$reset ${pad('')}$skyBlue║$reset');
    print('$skyBlue║$reset ${pad('$bold${white}Flutter Architecture CLI Tool$reset')}$skyBlue║$reset');
    print('$skyBlue║$reset ${pad('')}$skyBlue║$reset');

    // Divider
    print('$skyBlue╠${'═' * (boxWidth - 2)}╣$reset');

    // Info lines (compact)
    final versionLine = pad('${skyBlue}Version:$reset $white$version$reset');
    final devLine = pad('${skyBlue}Developed by:$reset $white$developer$reset');
    final ghLine = pad('${skyBlue}GitHub:$reset $white$underlineOn$githubUrl$underlineOff$reset');

    print('$skyBlue║$reset $versionLine$skyBlue║$reset');
    print('$skyBlue║$reset $devLine$skyBlue║$reset');
    print('$skyBlue║$reset $ghLine$skyBlue║$reset');

    // Bottom border
    print('$skyBlue╚${'═' * (boxWidth - 2)}╝$reset');
  }
}
