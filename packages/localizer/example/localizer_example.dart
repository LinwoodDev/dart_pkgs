import 'package:localizer/localizer.dart';

void main() {
  var localizer = Localizer();
  localizer.loadMap("en", {"hello-world": "Hello world!"});
  localizer.loadMap("es", {"hello-world": "Hola mundo!"});
  localizer.loadMap("fr", {"hello-world": "Bonjour le monde!"});
  localizer.loadMap("de", {"hello-world": "Hallo Welt!"});

  print("EN: ${localizer.get("en", "hello-world")}");
  print("ES: ${localizer.get("es", "hello-world")}");
  print("FR: ${localizer.get("fr", "hello-world")}");
  print("DE: ${localizer.get("de", "hello-world")}");
}
