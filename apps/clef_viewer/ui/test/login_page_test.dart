import 'package:clef_viewer_ui/pages/login_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders username, password and login button', (tester) async {
    await tester.pumpWidget(
      LoginPage(onSuccess: () {}),
    );

    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('CLEF Viewer'), findsOneWidget);
  });

  testWidgets('shows validation when fields are empty', (tester) async {
    await tester.pumpWidget(
      LoginPage(onSuccess: () {}),
    );

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o usuário'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });


}