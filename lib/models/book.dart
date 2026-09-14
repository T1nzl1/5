class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Book({required this.id, required this.title, required this.isbn, required this.year, required this.pages, required this.publisherId, required this.authorIds, required this.genreIds, required this.copiesTotal, required this.copiesAvailable, required this.createdAt, this.deletedAt});
  bool get isDeleted => deletedAt != null;

  Book copyWith({int? id, String? title, String? isbn, int? year, int? pages, int? publisherId, List<int>? authorIds, List<int>? genreIds, int? copiesTotal, int? copiesAvailable, DateTime? createdAt, DateTime? deletedAt, bool clearDeletedAt = false}) => Book(id: id ?? this.id, title: title ?? this.title, isbn: isbn ?? this.isbn, year: year ?? this.year, pages: pages ?? this.pages, publisherId: publisherId ?? this.publisherId, authorIds: authorIds ?? this.authorIds, genreIds: genreIds ?? this.genreIds, copiesTotal: copiesTotal ?? this.copiesTotal, copiesAvailable: copiesAvailable ?? this.copiesAvailable, createdAt: createdAt ?? this.createdAt, deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));

  Map<String,dynamic> toJson() => {'id':id,'title':title,'isbn':isbn,'year':year,'pages':pages,'publisherId':publisherId,'authorIds':authorIds,'genreIds':genreIds,'copiesTotal':copiesTotal,'copiesAvailable':copiesAvailable,'createdAt':createdAt.toIso8601String(),'deletedAt':deletedAt?.toIso8601String()};
  factory Book.fromJson(Map<String,dynamic> j) => Book(id:(j['id'] as num?)?.toInt() ?? 0,title:j['title'] as String? ?? '',isbn:j['isbn'] as String? ?? '',year:(j['year'] as num?)?.toInt() ?? 0,pages:(j['pages'] as num?)?.toInt() ?? 0,publisherId:(j['publisherId'] as num?)?.toInt() ?? 0,authorIds:(j['authorIds'] as List? ?? const []).map((e)=>(e as num).toInt()).toList(),genreIds:(j['genreIds'] as List? ?? const []).map((e)=>(e as num).toInt()).toList(),copiesTotal:(j['copiesTotal'] as num?)?.toInt() ?? 0,copiesAvailable:(j['copiesAvailable'] as num?)?.toInt() ?? 0,createdAt:DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),deletedAt:j['deletedAt']==null?null:DateTime.tryParse(j['deletedAt'].toString()));
}
