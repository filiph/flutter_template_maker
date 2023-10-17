A tool for automatically creating Flutter templates 
from existing Flutter projects.

First, create a copy of the `example/game_template.yaml` configuration file
and change values as appropriate. Then run the following command from the root
of this project:

```shell
dart bin/flutter_template_maker.dart path/to/your/config.yaml
```

The tool will generate files in the directories provided by the configuration
file.

In order to put `flutter_template_maker` into your $PATH, run the following
command from the root of this project:

```shell
dart pub global activate --source path .
```

Now it is possible to run `flutter_template_maker config.yaml` from anywhere.

