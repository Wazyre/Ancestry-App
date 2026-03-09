import 'package:ancestry_app/src/ui/mainMenu/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});

  @override
  State<LoginAdminScreen> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdminScreen> {

  final _loginFormKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('DEBUG: Enter anything for now'),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.loginUsernameLabel),
                validator: (value) {
                  // TODO validate against database here
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.loginUsernameWarning;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.loginPasswordLabel),
                validator: (value) {
                  // TODO validate against database here
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.loginPasswordWarning;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_loginFormKey.currentState!.validate()) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
                  }
                  else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.loginFormSubmitWarning)
                      )
                    );
                  }
                }, 
                child: Text(AppLocalizations.of(context)!.loginButton))
            ],
          )
        ),
      )
    );
  }
}