import 'package:flarch/flarch_commands.dart';

void main(List<String> arguments) async {
  final flarch = Flarch();
  await flarch.run(arguments);
}
