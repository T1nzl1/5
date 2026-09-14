class Author {
  final int id;
  final String fullName;
  final int birthYear;
  final String country;
  final DateTime? deletedAt;
  const Author({required this.id, required this.fullName, required this.birthYear, required this.country, this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Author copyWith({int? id,String? fullName,int? birthYear,String? country,DateTime? deletedAt,bool clearDeletedAt=false})=>Author(id:id??this.id,fullName:fullName??this.fullName,birthYear:birthYear??this.birthYear,country:country??this.country,deletedAt:clearDeletedAt?null:(deletedAt??this.deletedAt));
  Map<String,dynamic> toJson()=>{'id':id,'fullName':fullName,'birthYear':birthYear,'country':country,'deletedAt':deletedAt?.toIso8601String()};
  factory Author.fromJson(Map<String,dynamic> j)=>Author(id:(j['id'] as num?)?.toInt()??0,fullName:j['fullName'] as String? ?? '',birthYear:(j['birthYear'] as num?)?.toInt()??0,country:j['country'] as String? ?? '',deletedAt:j['deletedAt']==null?null:DateTime.tryParse(j['deletedAt'].toString()));
}
