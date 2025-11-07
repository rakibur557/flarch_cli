import 'package:flarch/flarch.dart';

/// Main entry point for the Flarch CLI tool.
/// 
/// This function is called when the `flarch` command is executed.
/// It creates a [Flarch] instance and runs it with the provided arguments.
/// 
/// - [arguments]: Command-line arguments passed to the CLI
void main(List<String> arguments) async {
  final flarch = Flarch();
  await flarch.run(arguments);
}
