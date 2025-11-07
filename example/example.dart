import 'package:flarch/flarch.dart';

/// Example demonstrating how to use the Flarch CLI programmatically.
/// 
/// This example shows how to create a [Flarch] instance and use it
/// to run commands programmatically instead of using the command line.
void main() async {
  // Create a Flarch instance
  final flarch = Flarch();

  // Print the usage guide
  flarch.printUsage();

  // Print version information
  flarch.printVersion();

  // Example: Run a command programmatically
  // await flarch.run(['init', 'my_app']);
  
  // Example: Create a feature
  // await flarch.run(['UserProfile']);
  
  // Example: List features
  // await flarch.run(['list']);
  
  // Example: Check project health
  // await flarch.run(['health']);
}

