import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final argParser = ArgParser(allowTrailingOptions: true);
  final parsedArgs = argParser.parse(args);
  final yamlPath = parsedArgs.rest.singleOrNull;

  if (yamlPath == null) {
    print("Missing path to YAML configuration file.\n");
    print("Usage: flutter_template_maker my_project.yaml");
    print(argParser.usage);
    exit(2);
  }

  YamlDocument document;
  try {
    var contents = File(yamlPath).readAsStringSync();
    document = loadYamlDocument(contents);
  } on IOException catch (e) {
    print("File '$yamlPath' couldn't be read: $e");
    exit(3);
  } on YamlException catch (e) {
    print("Parse error: $e");
    exit(99);
  } catch (e, s) {
    print("Error: $e\n$s");
    exit(3);
  }

  if (document.contents is! YamlMap) {
    print("Wrong yaml ('$yamlPath'): "
        "top level YAML structure should be a map");
  }

  var options = document.contents as YamlMap;

  var inputDirectoryPath = options['input_directory'] as String;

  var copyGlobPatterns =
      List.castFrom<dynamic, String>(options['copy_globs'] as List<dynamic>);
  var copyGlobs = copyGlobPatterns
      .map((pattern) => Glob(pattern, caseSensitive: true))
      .toList(growable: false);
  bool isCopyTemplate(String path) =>
      copyGlobs.any((glob) => glob.matches(path));

  var mustacheGlobPatterns = List.castFrom<dynamic, String>(
      options['mustache_globs'] as List<dynamic>);
  var mustacheGlobs = mustacheGlobPatterns
      .map((pattern) => Glob(pattern, caseSensitive: true))
      .toList(growable: false);
  bool isMustacheTemplate(String path) =>
      mustacheGlobs.any((glob) => glob.matches(path));

  var imageGlobPatterns =
      List.castFrom<dynamic, String>(options['image_globs'] as List<dynamic>);
  var imageGlobs = imageGlobPatterns
      .map((pattern) => Glob(pattern, caseSensitive: true))
      .toList(growable: false);
  bool isImageTemplate(String path) =>
      imageGlobs.any((glob) => glob.matches(path));

  var ignoreGlobPatterns =
      List.castFrom<dynamic, String>(options['ignore_globs'] as List<dynamic>);
  var ignoreGlobs = ignoreGlobPatterns
      .map((pattern) => Glob(pattern, caseSensitive: true))
      .toList(growable: false);
  bool isIgnored(String path) => ignoreGlobs.any((glob) => glob.matches(path));

  var outputDirectoryPath = options['output_directory'] as String;
  var outputDirectory = Directory(outputDirectoryPath);
  if (!outputDirectory.existsSync()) {
    print("Output directory '${outputDirectory.path}' doesn't exist. "
        "Creating.");
    outputDirectory.createSync(recursive: true);
  }

  var imagesDirectoryPath = options['output_images_directory'] as String;
  var imagesDirectory = Directory(imagesDirectoryPath);
  if (!imagesDirectory.existsSync()) {
    print("Images directory '${imagesDirectory.path}' doesn't exist. "
        "Creating.");
    imagesDirectory.createSync(recursive: true);
  }

  var projectName = options['project_name'];

  var inputDirectory = Directory(inputDirectoryPath);

  for (var entity in inputDirectory.listSync(recursive: true)) {
    if (entity is! File) continue;
    final file = entity;

    var relativePath = path.relative(file.path, from: inputDirectoryPath);
    var outPath = path.join(outputDirectoryPath, relativePath);

    if (isIgnored(relativePath)) {
      continue;
    }

    // Follows the same logic as flutter_tools/lib/src/template.dart.
    if (isCopyTemplate(relativePath)) {
      outPath += copyTemplateExtension;
      var outFile = File(outPath);
      // Create the file first in order to also create all intermediary folders.
      outFile.createSync(recursive: true);
      file.copySync(outPath);
    } else if (isImageTemplate(relativePath)) {
      outPath += imageTemplateExtension;
      // The file that goes to the output directory with other .tmpl files.
      var outFileEmpty = File(outPath);
      outFileEmpty.createSync(recursive: true);
      // The file that goes to the images repo.
      var copyFilePath = path.join(imagesDirectoryPath, relativePath);
      var copyFile = File(copyFilePath);
      // Create the file first in order to also create all intermediary folders.
      copyFile.createSync(recursive: true);
      file.copySync(copyFilePath);
    } else if (isMustacheTemplate(relativePath)) {
      outPath += templateExtension;
      var outFile = File(outPath);
      var contents = file.readAsStringSync();
      var modifiedContents =
          contents.replaceAll(projectName, projectNameSubstitution);
      // TODO: check if any replacement happened at all. If not, just use
      //       .copy.tmpl?
      outFile.createSync(recursive: true);
      outFile.writeAsStringSync(modifiedContents);
    }
  }
}

// These are from flutter/packages/flutter_tools/lib/src/template.dart.
const copyTemplateExtension = '.copy.tmpl';
const imageTemplateExtension = '.img.tmpl';
const templateExtension = '.tmpl';
const testTemplateExtension = '.test.tmpl';

const projectNameSubstitution = '{{projectName}}';
