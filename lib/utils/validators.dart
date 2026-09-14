class Validators {
  static String? requiredText(String? value,{String label='Поле',int maxLength=120}) { final v=value?.trim()??''; if(v.isEmpty)return '$label обязательно'; if(v.length>maxLength)return 'Не более $maxLength символов'; return null; }
  static String? intRange(String? value,{required String label,required int min,required int max}) { final v=value?.trim()??''; if(v.isEmpty)return '$label обязательно'; final n=int.tryParse(v); if(n==null)return 'Введите целое число'; if(n<min||n>max)return 'Допустимо: $min–$max'; return null; }
  static String? nonNegative(String? value,{required String label}) { final e=intRange(value,label:label,min:0,max:1000000); return e; }
  static String? positive(String? value,{required String label}) { return intRange(value,label:label,min:1,max:1000000); }
  static String? email(String? value) { final req=requiredText(value,label:'Email',maxLength:120); if(req!=null)return req; final v=value!.trim(); final re=RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$'); return re.hasMatch(v)?null:'Неверный формат email'; }
  static String? date(String? value,{required String label}) { final req=requiredText(value,label:label,maxLength:30); if(req!=null)return req; return DateTime.tryParse(value!.trim())==null?'Формат: ГГГГ-ММ-ДД':null; }
}
