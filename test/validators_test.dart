import 'package:flutter_test/flutter_test.dart';
import 'package:libraryden/utils/validators.dart';

void main() {
  group('Validators', () {
    test('requiredText rejects empty string', () => expect(Validators.requiredText('', label: 'Название'), isNotNull));
    test('requiredText accepts normal text', () => expect(Validators.requiredText('Война и мир', label: 'Название'), isNull));
    test('intRange rejects non-number', () => expect(Validators.intRange('abc', label: 'Год', min: 1000, max: 2100), isNotNull));
    test('intRange rejects value outside range', () => expect(Validators.intRange('999', label: 'Год', min: 1000, max: 2100), isNotNull));
    test('intRange accepts value in range', () => expect(Validators.intRange('2020', label: 'Год', min: 1000, max: 2100), isNull));
    test('email rejects invalid address', () => expect(Validators.email('wrong-address'), isNotNull));
    test('email accepts valid address', () => expect(Validators.email('reader@example.com'), isNull));
    test('date rejects invalid date', () => expect(Validators.date('not-a-date', label: 'Дата'), isNotNull));
  });
}
