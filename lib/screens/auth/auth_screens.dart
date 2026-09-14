import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state_auth.dart';
import '../../core/api_exceptions.dart';

class LoginScreen extends StatefulWidget{const LoginScreen({super.key});@override State<LoginScreen> createState()=>_LoginScreenState();}
class _LoginScreenState extends State<LoginScreen>{final u=TextEditingController(),p=TextEditingController();String? error;bool busy=false;@override Widget build(BuildContext context)=>_AuthCard(title:'Вход',child:Column(children:[TextField(controller:u,decoration:const InputDecoration(labelText:'Логин',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'Пароль',border:OutlineInputBorder())),if(error!=null)...[const SizedBox(height:10),Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))],const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:()async{if(u.text.trim().isEmpty||p.text.isEmpty){setState(()=>error='Заполните логин и пароль');return;}setState(()=>busy=true);try{await context.read<AuthNotifier>().login(u.text.trim(),p.text);if(mounted){final from=GoRouterState.of(context).uri.queryParameters['from'];context.go(from??'/');}}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}},child:Text(busy?'Вход...':'Войти'))),TextButton(onPressed:()=>context.go('/register'),child:const Text('Зарегистрироваться')),const Divider(),]));}
class RegisterScreen extends StatefulWidget{const RegisterScreen({super.key});@override State<RegisterScreen> createState()=>_RegisterScreenState();}
class _RegisterScreenState extends State<RegisterScreen>{final u=TextEditingController(),n=TextEditingController(),p=TextEditingController();String? error;bool busy=false;bool get len=>p.text.length>=8;bool get digit=>RegExp(r'\d').hasMatch(p.text);bool get special=>RegExp(r'[^A-Za-zА-Яа-я0-9]').hasMatch(p.text);@override Widget build(BuildContext context)=>_AuthCard(title:'Регистрация',child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Имя',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:u,decoration:const InputDecoration(labelText:'Логин',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:p,obscureText:true,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Пароль',border:OutlineInputBorder())),const SizedBox(height:10),_Rule(ok:len,text:'Не менее 8 символов'),_Rule(ok:digit,text:'Хотя бы одна цифра'),_Rule(ok:special,text:'Хотя бы один специальный символ'),if(error!=null)Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy||!len||!digit||!special?null:()async{if(u.text.trim().isEmpty||n.text.trim().isEmpty){setState(()=>error='Заполните имя и логин');return;}setState(()=>busy=true);try{await context.read<AuthNotifier>().register(u.text.trim(),n.text.trim(),p.text);if(mounted)context.go('/');}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}},child:const Text('Зарегистрироваться'))),TextButton(onPressed:()=>context.go('/login'),child:const Text('Войти'))]));}
class _Rule extends StatelessWidget{final bool ok;final String text;const _Rule({required this.ok,required this.text});@override Widget build(BuildContext c)=>Row(children:[Icon(ok?Icons.check_circle:Icons.cancel,size:18,color:ok?Colors.green:Theme.of(c).colorScheme.error),const SizedBox(width:6),Text(text)]);}
class _AuthCard extends StatelessWidget{final String title;final Widget child;const _AuthCard({required this.title,required this.child});@override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(child:Card(child:Container(width:420,padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(title,style:Theme.of(c).textTheme.headlineMedium),const SizedBox(height:24),child]))))));}
class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64),
              const SizedBox(height: 12),
              const Text('Доступ запрещён', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('У вашей роли нет прав для этого экрана.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.go('/'), child: const Text('На главную')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.security),
                label: const Text('Проверить защиту сервера (403)'),
                onPressed: () async {
                  try {
                    await context.read<Dio>().get('/admin/users');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запрос разрешён сервером.')));
                    }
                  } on DioException catch (e) {
                    final error = mapDioError(e);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Сервер: $error')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
}
