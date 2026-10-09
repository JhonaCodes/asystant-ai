// A private input card pre-fills only the public fields it is given a value
// for, and shows an email field in clear with an email keyboard.
import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/chat_private_input_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'pre-fills email and text fields but never a password, and shows the '
    'email in clear',
    (tester) async {
      const request = PrivateInputRequest(
        id: 'req-prefill',
        title: 'LoginFlow · DEV',
        fields: [
          PrivateInputField(
            name: 'email',
            label: 'Correo',
            kind: .email,
            initialValue: 'ops@loginflow.dev',
          ),
          PrivateInputField(
            name: 'company_id',
            label: 'ID de compañía',
            kind: .text,
            initialValue: 'company-typed',
          ),
          PrivateInputField(
            name: 'password',
            label: 'Contraseña',
            kind: .password,
            initialValue: 'leaked-secret',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPrivateInputCard(
              request: request,
              strings: const AsystantStrings(),
              onSubmit: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('ops@loginflow.dev'), findsOneWidget);
      expect(find.text('company-typed'), findsOneWidget);
      expect(find.text('leaked-secret'), findsNothing);

      final email = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Correo'),
      );
      expect(email.obscureText, isFalse);
      expect(email.keyboardType, TextInputType.emailAddress);
    },
  );
}
