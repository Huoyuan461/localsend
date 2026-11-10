import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhichuan_app/provider/persistence_provider.dart';

@GenerateNiceMocks([
  MockSpec<PersistenceService>(),
  MockSpec<SharedPreferences>(),
])
void main() {}
